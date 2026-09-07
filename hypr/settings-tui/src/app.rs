use crate::animations::{self, AnimationLeaf};
use crate::border_gradient::{self, BorderGradient};
use crate::hyprctl;
use crate::lua_readers::{self, AutostartEntry, Keybind, WindowRule, WorkspaceRange};
use crate::store::{self, Kind, SettingSpec, Value};
use std::time::{Duration, Instant};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PageId {
    Monitors,
    Appearance,
    Animations,
    Input,
    LayoutMisc,
    Workspaces,
    Keybinds,
    Autostart,
    WindowRules,
}

pub const PAGES: &[(PageId, &str)] = &[
    (PageId::Monitors, "Monitors"),
    (PageId::Appearance, "Appearance"),
    (PageId::Animations, "Animations"),
    (PageId::Input, "Input"),
    (PageId::LayoutMisc, "Layout & Misc"),
    (PageId::Workspaces, "Workspaces"),
    (PageId::Keybinds, "Keybinds"),
    (PageId::Autostart, "Autostart"),
    (PageId::WindowRules, "Window Rules"),
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Focus {
    Sidebar,
    Content,
}

pub struct SettingsGroup {
    pub title: &'static str,
    pub specs: Vec<SettingSpec>,
}

pub struct SettingsPage {
    pub groups: Vec<SettingsGroup>,
    pub values: Vec<Vec<Value>>,
    pub selected: usize,
}

pub enum Outcome {
    Applied,
    NeedsEdit,
    Error(String),
}

impl SettingsPage {
    pub fn new(groups: Vec<SettingsGroup>) -> Self {
        let values = groups
            .iter()
            .map(|g| g.specs.iter().map(|s| s.get().unwrap_or(Value::Str(String::new()))).collect())
            .collect();
        Self { groups, values, selected: 0 }
    }

    pub fn flat(&self) -> Vec<(usize, usize)> {
        let mut v = Vec::new();
        for (gi, g) in self.groups.iter().enumerate() {
            for si in 0..g.specs.len() {
                v.push((gi, si));
            }
        }
        v
    }

    pub fn selected_pos(&self) -> Option<(usize, usize)> {
        self.flat().get(self.selected).copied()
    }

    pub fn selected_spec(&self) -> Option<&SettingSpec> {
        let (gi, si) = self.selected_pos()?;
        Some(&self.groups[gi].specs[si])
    }

    pub fn move_selection(&mut self, delta: i32) {
        let len = self.flat().len();
        if len == 0 {
            return;
        }
        let next = (self.selected as i32 + delta).clamp(0, len as i32 - 1);
        self.selected = next as usize;
    }

    pub fn adjust(&mut self, dir: i32) -> Outcome {
        let Some((gi, si)) = self.selected_pos() else { return Outcome::Error("nothing selected".into()) };
        let spec = &self.groups[gi].specs[si];
        let cur = self.values[gi][si].clone();
        let new_val = match spec.kind {
            Kind::Bool => Value::Bool(!cur.as_bool()),
            Kind::Int => Value::Int((cur.as_f64() + spec.step * dir as f64).clamp(spec.min, spec.max) as i64),
            Kind::Float => {
                let stepped = (cur.as_f64() + spec.step * dir as f64).clamp(spec.min, spec.max);
                let rounded = (stepped / spec.step).round() * spec.step;
                Value::Float(rounded)
            }
            Kind::ChoiceStr | Kind::ChoiceInt => match spec.cycle_choice(cur.as_str(), dir) {
                Some(next) => Value::Str(next),
                None => return Outcome::Error("no choices".into()),
            },
            Kind::Str => return Outcome::NeedsEdit,
        };
        match spec.set(&new_val) {
            Ok(()) => {
                self.values[gi][si] = new_val;
                Outcome::Applied
            }
            Err(e) => Outcome::Error(e.to_string()),
        }
    }

    pub fn primary_action(&mut self) -> Outcome {
        let Some(spec) = self.selected_spec() else { return Outcome::Error("nothing selected".into()) };
        match spec.kind {
            Kind::Bool => self.adjust(1),
            Kind::ChoiceStr | Kind::ChoiceInt => self.adjust(1),
            Kind::Int | Kind::Float | Kind::Str => Outcome::NeedsEdit,
        }
    }

    pub fn edit_seed(&self) -> Option<String> {
        let (gi, si) = self.selected_pos()?;
        Some(self.values[gi][si].as_str_display())
    }

    pub fn commit_edit(&mut self, text: &str) -> Outcome {
        let Some((gi, si)) = self.selected_pos() else { return Outcome::Error("nothing selected".into()) };
        let spec = &self.groups[gi].specs[si];
        let new_val = match spec.kind {
            Kind::Int => match text.trim().parse::<f64>() {
                Ok(n) => Value::Int(n.clamp(spec.min, spec.max) as i64),
                Err(_) => return Outcome::Error("not a number".into()),
            },
            Kind::Float => match text.trim().parse::<f64>() {
                Ok(n) => Value::Float(n.clamp(spec.min, spec.max)),
                Err(_) => return Outcome::Error("not a number".into()),
            },
            Kind::Str => Value::Str(text.to_string()),
            Kind::Bool | Kind::ChoiceStr | Kind::ChoiceInt => return Outcome::Error("not editable as text".into()),
        };
        match spec.set(&new_val) {
            Ok(()) => {
                self.values[gi][si] = new_val;
                Outcome::Applied
            }
            Err(e) => Outcome::Error(e.to_string()),
        }
    }
}

impl Value {
    pub fn as_str_display(&self) -> String {
        match self {
            Value::Bool(b) => b.to_string(),
            Value::Int(n) => n.to_string(),
            Value::Float(f) => format!("{f}"),
            Value::Str(s) => s.clone(),
        }
    }
}

pub struct AppearancePage {
    pub gaps_borders: SettingsPageStub,
    pub border: BorderGradient,
    pub inactive_border: SettingSpec,
    pub inactive_border_val: Value,
    pub corners_opacity: SettingsPageStub,
    pub shadow: SettingsPageStub,
    pub blur: SettingsPageStub,
    pub selected: usize,
}

/// A group of specs + cached values, without its own cursor (Appearance
/// tracks one flat cursor across all its sub-groups, including the
/// border-gradient rows, so the generic `SettingsPage` cursor isn't used
/// here).
pub struct SettingsPageStub {
    pub title: &'static str,
    pub specs: Vec<SettingSpec>,
    pub values: Vec<Value>,
}

impl SettingsPageStub {
    fn new(title: &'static str, specs: Vec<SettingSpec>) -> Self {
        let values = specs.iter().map(|s| s.get().unwrap_or(Value::Str(String::new()))).collect();
        Self { title, specs, values }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ApRowRef {
    GapsBorders(usize),
    BorderColor(usize),
    BorderAngle,
    InactiveBorder,
    CornersOpacity(usize),
    Shadow(usize),
    Blur(usize),
}

impl AppearancePage {
    pub fn new() -> Self {
        Self {
            gaps_borders: SettingsPageStub::new("Gaps & borders", store::appearance_gaps_borders()),
            border: border_gradient::get_active_border().unwrap_or(BorderGradient { colors: vec!["rgba(ffffffff)".into()], angle: 0 }),
            inactive_border: store::appearance_colors().remove(0),
            inactive_border_val: Value::Str(String::new()),
            corners_opacity: SettingsPageStub::new("Corners & opacity", store::appearance_corners_opacity()),
            shadow: SettingsPageStub::new("Shadow", store::appearance_shadow()),
            blur: SettingsPageStub::new("Blur", store::appearance_blur()),
            selected: 0,
        }
        .with_inactive_loaded()
    }

    fn with_inactive_loaded(mut self) -> Self {
        self.inactive_border_val = self.inactive_border.get().unwrap_or(Value::Str(String::new()));
        self
    }

    pub fn rows(&self) -> Vec<(bool, &'static str, ApRowRef)> {
        let mut out = Vec::new();
        for i in 0..self.gaps_borders.specs.len() {
            out.push((i == 0, self.gaps_borders.title, ApRowRef::GapsBorders(i)));
        }
        out.push((true, "Active border color", ApRowRef::BorderColor(0)));
        out.push((false, "", ApRowRef::BorderColor(1)));
        out.push((false, "", ApRowRef::BorderAngle));
        out.push((true, "Inactive border", ApRowRef::InactiveBorder));
        for i in 0..self.corners_opacity.specs.len() {
            out.push((i == 0, self.corners_opacity.title, ApRowRef::CornersOpacity(i)));
        }
        for i in 0..self.shadow.specs.len() {
            out.push((i == 0, self.shadow.title, ApRowRef::Shadow(i)));
        }
        for i in 0..self.blur.specs.len() {
            out.push((i == 0, self.blur.title, ApRowRef::Blur(i)));
        }
        out
    }

    pub fn move_selection(&mut self, delta: i32) {
        let len = self.rows().len();
        if len == 0 {
            return;
        }
        let next = (self.selected as i32 + delta).clamp(0, len as i32 - 1);
        self.selected = next as usize;
    }

    pub fn selected_ref(&self) -> Option<ApRowRef> {
        self.rows().get(self.selected).map(|(_, _, r)| *r)
    }

    fn push_border(&mut self) -> Outcome {
        match border_gradient::set_active_border(&self.border) {
            Ok(()) => Outcome::Applied,
            Err(e) => Outcome::Error(e.to_string()),
        }
    }

    pub fn adjust(&mut self, dir: i32) -> Outcome {
        match self.selected_ref() {
            Some(ApRowRef::GapsBorders(i)) => adjust_stub(&mut self.gaps_borders, i, dir),
            Some(ApRowRef::CornersOpacity(i)) => adjust_stub(&mut self.corners_opacity, i, dir),
            Some(ApRowRef::Shadow(i)) => adjust_stub(&mut self.shadow, i, dir),
            Some(ApRowRef::Blur(i)) => adjust_stub(&mut self.blur, i, dir),
            Some(ApRowRef::BorderAngle) => {
                self.border.angle = (self.border.angle + 5 * dir as i64).rem_euclid(360);
                self.push_border()
            }
            Some(ApRowRef::BorderColor(_)) | Some(ApRowRef::InactiveBorder) | None => Outcome::NeedsEdit,
        }
    }

    pub fn primary_action(&mut self) -> Outcome {
        match self.selected_ref() {
            Some(ApRowRef::GapsBorders(i)) => primary_stub(&mut self.gaps_borders, i),
            Some(ApRowRef::CornersOpacity(i)) => primary_stub(&mut self.corners_opacity, i),
            Some(ApRowRef::Shadow(i)) => primary_stub(&mut self.shadow, i),
            Some(ApRowRef::Blur(i)) => primary_stub(&mut self.blur, i),
            Some(ApRowRef::BorderAngle) => Outcome::NeedsEdit,
            Some(ApRowRef::BorderColor(_)) | Some(ApRowRef::InactiveBorder) => Outcome::NeedsEdit,
            None => Outcome::Error("nothing selected".into()),
        }
    }

    pub fn edit_seed(&self) -> Option<String> {
        match self.selected_ref()? {
            ApRowRef::GapsBorders(i) => Some(self.gaps_borders.values[i].as_str_display()),
            ApRowRef::CornersOpacity(i) => Some(self.corners_opacity.values[i].as_str_display()),
            ApRowRef::Shadow(i) => Some(self.shadow.values[i].as_str_display()),
            ApRowRef::Blur(i) => Some(self.blur.values[i].as_str_display()),
            ApRowRef::BorderColor(i) => self.border.colors.get(i).cloned().or(Some(String::new())),
            ApRowRef::BorderAngle => Some(self.border.angle.to_string()),
            ApRowRef::InactiveBorder => Some(self.inactive_border_val.as_str_display()),
        }
    }

    pub fn commit_edit(&mut self, text: &str) -> Outcome {
        match self.selected_ref() {
            Some(ApRowRef::GapsBorders(i)) => commit_stub(&mut self.gaps_borders, i, text),
            Some(ApRowRef::CornersOpacity(i)) => commit_stub(&mut self.corners_opacity, i, text),
            Some(ApRowRef::Shadow(i)) => commit_stub(&mut self.shadow, i, text),
            Some(ApRowRef::Blur(i)) => commit_stub(&mut self.blur, i, text),
            Some(ApRowRef::BorderColor(i)) => {
                if i >= self.border.colors.len() {
                    self.border.colors.push(text.to_string());
                } else if text.trim().is_empty() && i == 1 {
                    self.border.colors.truncate(1);
                } else {
                    self.border.colors[i] = text.to_string();
                }
                if self.border.colors.is_empty() {
                    self.border.colors.push("rgba(ffffffff)".to_string());
                }
                self.push_border()
            }
            Some(ApRowRef::BorderAngle) => match text.trim().parse::<i64>() {
                Ok(n) => {
                    self.border.angle = n.rem_euclid(360);
                    self.push_border()
                }
                Err(_) => Outcome::Error("not a number".into()),
            },
            Some(ApRowRef::InactiveBorder) => {
                let val = Value::Str(text.to_string());
                match self.inactive_border.set(&val) {
                    Ok(()) => {
                        self.inactive_border_val = val;
                        Outcome::Applied
                    }
                    Err(e) => Outcome::Error(e.to_string()),
                }
            }
            None => Outcome::Error("nothing selected".into()),
        }
    }
}

fn adjust_stub(stub: &mut SettingsPageStub, i: usize, dir: i32) -> Outcome {
    let spec = &stub.specs[i];
    let cur = stub.values[i].clone();
    let new_val = match spec.kind {
        Kind::Bool => Value::Bool(!cur.as_bool()),
        Kind::Int => Value::Int((cur.as_f64() + spec.step * dir as f64).clamp(spec.min, spec.max) as i64),
        Kind::Float => {
            let stepped = (cur.as_f64() + spec.step * dir as f64).clamp(spec.min, spec.max);
            Value::Float((stepped / spec.step).round() * spec.step)
        }
        Kind::ChoiceStr | Kind::ChoiceInt => match spec.cycle_choice(cur.as_str(), dir) {
            Some(next) => Value::Str(next),
            None => return Outcome::Error("no choices".into()),
        },
        Kind::Str => return Outcome::NeedsEdit,
    };
    match spec.set(&new_val) {
        Ok(()) => {
            stub.values[i] = new_val;
            Outcome::Applied
        }
        Err(e) => Outcome::Error(e.to_string()),
    }
}

fn primary_stub(stub: &mut SettingsPageStub, i: usize) -> Outcome {
    match stub.specs[i].kind {
        Kind::Bool | Kind::ChoiceStr | Kind::ChoiceInt => adjust_stub(stub, i, 1),
        Kind::Int | Kind::Float | Kind::Str => Outcome::NeedsEdit,
    }
}

fn commit_stub(stub: &mut SettingsPageStub, i: usize, text: &str) -> Outcome {
    let spec = &stub.specs[i];
    let new_val = match spec.kind {
        Kind::Int => match text.trim().parse::<f64>() {
            Ok(n) => Value::Int(n.clamp(spec.min, spec.max) as i64),
            Err(_) => return Outcome::Error("not a number".into()),
        },
        Kind::Float => match text.trim().parse::<f64>() {
            Ok(n) => Value::Float(n.clamp(spec.min, spec.max)),
            Err(_) => return Outcome::Error("not a number".into()),
        },
        Kind::Str => Value::Str(text.to_string()),
        Kind::Bool | Kind::ChoiceStr | Kind::ChoiceInt => return Outcome::Error("not editable as text".into()),
    };
    match spec.set(&new_val) {
        Ok(()) => {
            stub.values[i] = new_val;
            Outcome::Applied
        }
        Err(e) => Outcome::Error(e.to_string()),
    }
}

pub struct AnimationsPage {
    pub enabled_spec: SettingSpec,
    pub enabled_val: Value,
    pub leaves: Vec<AnimationLeaf>,
    pub selected: usize,
}

impl AnimationsPage {
    pub fn new() -> Self {
        let enabled_spec = animations::animations_enabled_spec();
        let enabled_val = enabled_spec.get().unwrap_or(Value::Bool(false));
        let leaves = animations::parse_animations().unwrap_or_default();
        Self { enabled_spec, enabled_val, leaves, selected: 0 }
    }

    pub fn move_selection(&mut self, delta: i32) {
        let len = self.leaves.len() + 1;
        if len == 0 {
            return;
        }
        let next = (self.selected as i32 + delta).clamp(0, len as i32 - 1);
        self.selected = next as usize;
    }

    pub fn toggle_master(&mut self) -> Outcome {
        let new_val = Value::Bool(!self.enabled_val.as_bool());
        match self.enabled_spec.set(&new_val) {
            Ok(()) => {
                self.enabled_val = new_val;
                Outcome::Applied
            }
            Err(e) => Outcome::Error(e.to_string()),
        }
    }

    pub fn toggle_leaf(&mut self) -> Outcome {
        if self.selected == 0 {
            return self.toggle_master();
        }
        let leaf = &mut self.leaves[self.selected - 1];
        leaf.enabled = !leaf.enabled;
        match animations::set_animation(leaf) {
            Ok(()) => Outcome::Applied,
            Err(e) => Outcome::Error(e.to_string()),
        }
    }

    pub fn adjust_speed(&mut self, dir: i32) -> Outcome {
        if self.selected == 0 {
            return self.toggle_master();
        }
        let leaf = &mut self.leaves[self.selected - 1];
        leaf.speed = (leaf.speed + 0.1 * dir as f64).clamp(0.1, 15.0);
        leaf.speed = (leaf.speed * 100.0).round() / 100.0;
        match animations::set_animation(leaf) {
            Ok(()) => Outcome::Applied,
            Err(e) => Outcome::Error(e.to_string()),
        }
    }
}

pub struct ListPage<T> {
    pub items: Vec<T>,
    pub selected: usize,
    pub search: String,
}

impl<T> ListPage<T> {
    fn new(items: Vec<T>) -> Self {
        Self { items, selected: 0, search: String::new() }
    }
}

pub struct EditState {
    pub buffer: String,
    pub label: String,
}

pub struct App {
    pub page_index: usize,
    pub focus: Focus,
    pub appearance: AppearancePage,
    pub animations: AnimationsPage,
    pub input: SettingsPage,
    pub layout_misc: SettingsPage,
    pub monitors: serde_json::Value,
    pub workspaces: Vec<WorkspaceRange>,
    pub workspace_specials: Vec<String>,
    pub keybinds: ListPage<Keybind>,
    pub autostart: ListPage<AutostartEntry>,
    pub windowrules: ListPage<WindowRule>,
    pub expanded_rule: Option<usize>,
    pub editing: Option<EditState>,
    pub searching: bool,
    pub status: Option<(String, Instant, bool)>,
    pub should_quit: bool,
}

impl App {
    pub fn new() -> Self {
        Self {
            page_index: 0,
            focus: Focus::Sidebar,
            appearance: AppearancePage::new(),
            animations: AnimationsPage::new(),
            input: SettingsPage::new(vec![
                SettingsGroup { title: "Keyboard", specs: store::input_keyboard() },
                SettingsGroup { title: "Mouse", specs: store::input_mouse() },
                SettingsGroup { title: "Touchpad", specs: store::input_touchpad() },
            ]),
            layout_misc: SettingsPage::new(vec![SettingsGroup { title: "Layout & startup behavior", specs: store::layout_misc() }]),
            monitors: hyprctl::monitors().unwrap_or(serde_json::Value::Array(vec![])),
            workspaces: lua_readers::parse_workspace_ranges().unwrap_or_default(),
            workspace_specials: lua_readers::parse_workspace_rules_raw().unwrap_or_default(),
            keybinds: ListPage::new(lua_readers::parse_keybinds().unwrap_or_default()),
            autostart: ListPage::new(lua_readers::parse_autostart().unwrap_or_default()),
            windowrules: ListPage::new(lua_readers::parse_window_rules().unwrap_or_default()),
            expanded_rule: None,
            editing: None,
            searching: false,
            status: None,
            should_quit: false,
        }
    }

    pub fn current_page(&self) -> PageId {
        PAGES[self.page_index].0
    }

    pub fn set_status(&mut self, msg: impl Into<String>, is_error: bool) {
        self.status = Some((msg.into(), Instant::now(), is_error));
    }

    pub fn status_text(&self) -> Option<(&str, bool)> {
        let (msg, at, is_err) = self.status.as_ref()?;
        if at.elapsed() > Duration::from_secs(4) {
            return None;
        }
        Some((msg.as_str(), *is_err))
    }

    fn apply_outcome(&mut self, outcome: Outcome) {
        match outcome {
            Outcome::Applied => self.set_status("applied", false),
            Outcome::Error(e) => self.set_status(e, true),
            Outcome::NeedsEdit => {}
        }
    }

    pub fn refresh_current_page(&mut self) {
        match self.current_page() {
            PageId::Monitors => self.monitors = hyprctl::monitors().unwrap_or(serde_json::Value::Array(vec![])),
            PageId::Appearance => self.appearance = AppearancePage::new(),
            PageId::Animations => self.animations = AnimationsPage::new(),
            PageId::Input => {
                self.input = SettingsPage::new(vec![
                    SettingsGroup { title: "Keyboard", specs: store::input_keyboard() },
                    SettingsGroup { title: "Mouse", specs: store::input_mouse() },
                    SettingsGroup { title: "Touchpad", specs: store::input_touchpad() },
                ])
            }
            PageId::LayoutMisc => {
                self.layout_misc = SettingsPage::new(vec![SettingsGroup { title: "Layout & startup behavior", specs: store::layout_misc() }])
            }
            PageId::Workspaces => {
                self.workspaces = lua_readers::parse_workspace_ranges().unwrap_or_default();
                self.workspace_specials = lua_readers::parse_workspace_rules_raw().unwrap_or_default();
            }
            PageId::Keybinds => self.keybinds.items = lua_readers::parse_keybinds().unwrap_or_default(),
            PageId::Autostart => self.autostart.items = lua_readers::parse_autostart().unwrap_or_default(),
            PageId::WindowRules => self.windowrules.items = lua_readers::parse_window_rules().unwrap_or_default(),
        }
        self.set_status("refreshed", false);
    }

    fn move_content_selection(&mut self, delta: i32) {
        match self.current_page() {
            PageId::Appearance => self.appearance.move_selection(delta),
            PageId::Animations => self.animations.move_selection(delta),
            PageId::Input => self.input.move_selection(delta),
            PageId::LayoutMisc => self.layout_misc.move_selection(delta),
            PageId::Keybinds => move_list(&mut self.keybinds, delta, keybind_haystack),
            PageId::Autostart => move_list(&mut self.autostart, delta, autostart_haystack),
            PageId::WindowRules => move_list(&mut self.windowrules, delta, windowrule_haystack),
            PageId::Monitors | PageId::Workspaces => {}
        }
    }

    pub fn handle_key(&mut self, key: crossterm::event::KeyEvent) {
        use crossterm::event::{KeyCode, KeyModifiers};

        if let Some(edit) = &mut self.editing {
            match key.code {
                KeyCode::Esc => {
                    self.editing = None;
                }
                KeyCode::Enter => {
                    let text = edit.buffer.clone();
                    self.editing = None;
                    let outcome = self.commit_edit(&text);
                    self.apply_outcome(outcome);
                }
                KeyCode::Backspace => {
                    edit.buffer.pop();
                }
                KeyCode::Char(c) => {
                    edit.buffer.push(c);
                }
                _ => {}
            }
            return;
        }

        if self.searching {
            let search = self.current_search_mut();
            match key.code {
                KeyCode::Esc | KeyCode::Enter => self.searching = false,
                KeyCode::Backspace => {
                    if let Some(s) = search {
                        s.pop();
                    }
                }
                KeyCode::Char(c) => {
                    if let Some(s) = search {
                        s.push(c);
                    }
                }
                _ => {}
            }
            return;
        }

        match key.code {
            KeyCode::Char('q') => self.should_quit = true,
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => self.should_quit = true,
            KeyCode::Char('r') => self.refresh_current_page(),
            KeyCode::Char('/') if matches!(self.current_page(), PageId::Keybinds | PageId::Autostart | PageId::WindowRules) => {
                self.searching = true;
                self.focus = Focus::Content;
            }
            KeyCode::Tab => {
                self.focus = match self.focus {
                    Focus::Sidebar => Focus::Content,
                    Focus::Content => Focus::Sidebar,
                };
            }
            KeyCode::Esc => self.focus = Focus::Sidebar,
            KeyCode::Up | KeyCode::Char('k') => match self.focus {
                Focus::Sidebar => {
                    self.page_index = self.page_index.saturating_sub(1);
                }
                Focus::Content => self.move_content_selection(-1),
            },
            KeyCode::Down | KeyCode::Char('j') => match self.focus {
                Focus::Sidebar => {
                    self.page_index = (self.page_index + 1).min(PAGES.len() - 1);
                }
                Focus::Content => self.move_content_selection(1),
            },
            KeyCode::Right | KeyCode::Char('l') => match self.focus {
                Focus::Sidebar => self.focus = Focus::Content,
                Focus::Content => self.adjust(1),
            },
            KeyCode::Left | KeyCode::Char('h') => match self.focus {
                Focus::Sidebar => {}
                Focus::Content => self.adjust(-1),
            },
            KeyCode::Enter => match self.focus {
                Focus::Sidebar => self.focus = Focus::Content,
                Focus::Content => self.primary_action(),
            },
            KeyCode::Char(' ') => {
                if self.focus == Focus::Content {
                    self.primary_action();
                }
            }
            _ => {}
        }
    }

    fn current_search_mut(&mut self) -> Option<&mut String> {
        match self.current_page() {
            PageId::Keybinds => Some(&mut self.keybinds.search),
            PageId::Autostart => Some(&mut self.autostart.search),
            PageId::WindowRules => Some(&mut self.windowrules.search),
            _ => None,
        }
    }

    fn adjust(&mut self, dir: i32) {
        let outcome = match self.current_page() {
            PageId::Appearance => self.appearance.adjust(dir),
            PageId::Animations => self.animations.adjust_speed(dir),
            PageId::Input => self.input.adjust(dir),
            PageId::LayoutMisc => self.layout_misc.adjust(dir),
            PageId::WindowRules if self.expanded_rule.is_some() => {
                self.expanded_rule = None;
                return;
            }
            _ => return,
        };
        self.apply_outcome(outcome);
    }

    fn primary_action(&mut self) {
        match self.current_page() {
            PageId::Appearance => {
                let outcome = self.appearance.primary_action();
                if matches!(outcome, Outcome::NeedsEdit) {
                    self.start_edit(self.appearance.edit_seed().unwrap_or_default(), edit_label_appearance(&self.appearance));
                } else {
                    self.apply_outcome(outcome);
                }
            }
            PageId::Animations => {
                let outcome = self.animations.toggle_leaf();
                self.apply_outcome(outcome);
            }
            PageId::Input => {
                let outcome = self.input.primary_action();
                if matches!(outcome, Outcome::NeedsEdit) {
                    let label = self.input.selected_spec().map(|s| s.label.to_string()).unwrap_or_default();
                    self.start_edit(self.input.edit_seed().unwrap_or_default(), label);
                } else {
                    self.apply_outcome(outcome);
                }
            }
            PageId::LayoutMisc => {
                let outcome = self.layout_misc.primary_action();
                if matches!(outcome, Outcome::NeedsEdit) {
                    let label = self.layout_misc.selected_spec().map(|s| s.label.to_string()).unwrap_or_default();
                    self.start_edit(self.layout_misc.edit_seed().unwrap_or_default(), label);
                } else {
                    self.apply_outcome(outcome);
                }
            }
            PageId::WindowRules => {
                if !self.windowrules.items.is_empty() {
                    self.expanded_rule = match self.expanded_rule {
                        Some(i) if i == self.windowrules.selected => None,
                        _ => Some(self.windowrules.selected),
                    };
                }
            }
            PageId::Monitors | PageId::Workspaces | PageId::Keybinds | PageId::Autostart => {}
        }
    }

    fn start_edit(&mut self, seed: String, label: String) {
        self.editing = Some(EditState { buffer: seed, label });
    }

    fn commit_edit(&mut self, text: &str) -> Outcome {
        match self.current_page() {
            PageId::Appearance => self.appearance.commit_edit(text),
            PageId::Input => self.input.commit_edit(text),
            PageId::LayoutMisc => self.layout_misc.commit_edit(text),
            _ => Outcome::Error("not editable".into()),
        }
    }
}

fn edit_label_appearance(page: &AppearancePage) -> String {
    match page.selected_ref() {
        Some(ApRowRef::GapsBorders(i)) => page.gaps_borders.specs[i].label.to_string(),
        Some(ApRowRef::CornersOpacity(i)) => page.corners_opacity.specs[i].label.to_string(),
        Some(ApRowRef::Shadow(i)) => page.shadow.specs[i].label.to_string(),
        Some(ApRowRef::Blur(i)) => page.blur.specs[i].label.to_string(),
        Some(ApRowRef::BorderColor(i)) => format!("Color {}", i + 1),
        Some(ApRowRef::BorderAngle) => "Gradient angle".to_string(),
        Some(ApRowRef::InactiveBorder) => page.inactive_border.label.to_string(),
        None => String::new(),
    }
}

fn move_list<T>(page: &mut ListPage<T>, delta: i32, haystack: impl Fn(&T) -> String) {
    let visible: Vec<usize> = page
        .items
        .iter()
        .enumerate()
        .filter(|(_, item)| page.search.is_empty() || haystack(item).to_lowercase().contains(&page.search.to_lowercase()))
        .map(|(i, _)| i)
        .collect();
    if visible.is_empty() {
        return;
    }
    let cur_pos = visible.iter().position(|&i| i == page.selected).unwrap_or(0);
    let next_pos = (cur_pos as i32 + delta).clamp(0, visible.len() as i32 - 1) as usize;
    page.selected = visible[next_pos];
}

pub fn keybind_haystack(b: &Keybind) -> String {
    format!("{} {} {} {}", b.combo, b.action, b.submap, b.comment)
}
pub fn autostart_haystack(a: &AutostartEntry) -> String {
    format!("{} {}", a.command, a.comment)
}
pub fn windowrule_haystack(w: &WindowRule) -> String {
    format!("{} {} {}", w.name, w.kind, w.comment)
}
