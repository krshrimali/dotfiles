use crate::app::{ApRowRef, App, Focus, PageId, PAGES};
use crate::colorutil::blended_rgb;
use crate::store::{Kind, Value};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Clear, List, ListItem, ListState, Paragraph, Wrap},
    Frame,
};

const ACCENT: Color = Color::Rgb(122, 162, 247);
const ACCENT_DIM: Color = Color::Rgb(70, 90, 130);
const GOOD: Color = Color::Rgb(158, 206, 106);
const WARN: Color = Color::Rgb(224, 175, 104);
const BAD: Color = Color::Rgb(247, 118, 142);
const MUTED: Color = Color::Rgb(120, 130, 150);
const TEXT: Color = Color::Rgb(220, 224, 235);

pub fn draw(f: &mut Frame, app: &App) {
    let root = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(3), Constraint::Length(1)])
        .split(f.area());

    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Length(24), Constraint::Min(20)])
        .split(root[0]);

    draw_sidebar(f, app, cols[0]);
    draw_content(f, app, cols[1]);
    draw_statusbar(f, app, root[1]);

    if let Some(edit) = &app.editing {
        draw_edit_popup(f, &edit.label, &edit.buffer);
    }
}

fn draw_sidebar(f: &mut Frame, app: &App, area: Rect) {
    let focused = app.focus == Focus::Sidebar;
    let items: Vec<ListItem> = PAGES
        .iter()
        .enumerate()
        .map(|(i, (_, title))| {
            let selected = i == app.page_index;
            let style = if selected && focused {
                Style::default().fg(Color::Black).bg(ACCENT).add_modifier(Modifier::BOLD)
            } else if selected {
                Style::default().fg(ACCENT).add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(TEXT)
            };
            ListItem::new(Line::from(format!(" {title}"))).style(style)
        })
        .collect();

    let block = Block::default()
        .title(" Hyprland Settings ")
        .title_style(Style::default().fg(ACCENT).add_modifier(Modifier::BOLD))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(if focused { Style::default().fg(ACCENT) } else { Style::default().fg(ACCENT_DIM) });

    f.render_widget(List::new(items).block(block), area);
}

fn draw_statusbar(f: &mut Frame, app: &App, area: Rect) {
    let mut spans = vec![
        Span::styled(" Tab ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" switch focus  "),
        Span::styled(" ↑↓ ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" navigate  "),
        Span::styled(" ←→ ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" adjust  "),
        Span::styled(" Enter ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" toggle/edit  "),
        Span::styled(" r ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" refresh  "),
        Span::styled(" q ", Style::default().fg(Color::Black).bg(ACCENT_DIM)),
        Span::raw(" quit "),
    ];
    if let Some((msg, is_err)) = app.status_text() {
        spans.push(Span::raw("  │  "));
        spans.push(Span::styled(msg, Style::default().fg(if is_err { BAD } else { GOOD }).add_modifier(Modifier::BOLD)));
    }
    f.render_widget(Paragraph::new(Line::from(spans)).style(Style::default().fg(MUTED)), area);
}

fn draw_edit_popup(f: &mut Frame, label: &str, buffer: &str) {
    let area = f.area();
    let w = (area.width * 2 / 3).clamp(30, 70);
    let popup = Rect {
        x: (area.width.saturating_sub(w)) / 2,
        y: area.height / 2 - 2,
        width: w,
        height: 5,
    };
    f.render_widget(Clear, popup);
    let block = Block::default()
        .title(format!(" Edit: {label} "))
        .title_style(Style::default().fg(ACCENT).add_modifier(Modifier::BOLD))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(ACCENT));
    let inner = block.inner(popup);
    f.render_widget(block, popup);
    let text = Paragraph::new(Line::from(vec![
        Span::styled(buffer, Style::default().fg(TEXT)),
        Span::styled("▏", Style::default().fg(ACCENT).add_modifier(Modifier::SLOW_BLINK)),
    ]))
    .wrap(Wrap { trim: false });
    f.render_widget(text, inner);
    let hint = Rect { x: inner.x, y: inner.y + 2, width: inner.width, height: 1 };
    f.render_widget(
        Paragraph::new(Line::from("Enter to apply · Esc to cancel")).style(Style::default().fg(MUTED)),
        hint,
    );
}

fn draw_content(f: &mut Frame, app: &App, area: Rect) {
    let focused = app.focus == Focus::Content;
    let title = PAGES[app.page_index].1;
    let block = Block::default()
        .title(format!(" {title} "))
        .title_style(Style::default().fg(ACCENT).add_modifier(Modifier::BOLD))
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(if focused { Style::default().fg(ACCENT) } else { Style::default().fg(ACCENT_DIM) });
    let inner = block.inner(area);
    f.render_widget(block, area);

    match app.current_page() {
        PageId::Monitors => draw_monitors(f, app, inner),
        PageId::Appearance => draw_appearance(f, app, inner),
        PageId::Animations => draw_animations(f, app, inner),
        PageId::Input => draw_settings_page(f, &app.input.groups_view(), app.input.selected, inner),
        PageId::LayoutMisc => draw_settings_page(f, &app.layout_misc.groups_view(), app.layout_misc.selected, inner),
        PageId::Workspaces => draw_workspaces(f, app, inner),
        PageId::Keybinds => draw_keybinds(f, app, inner),
        PageId::Autostart => draw_autostart(f, app, inner),
        PageId::WindowRules => draw_windowrules(f, app, inner),
    }
}

fn value_style(kind: Kind) -> Style {
    match kind {
        Kind::Bool => Style::default(),
        Kind::Int | Kind::Float => Style::default().fg(Color::Rgb(180, 210, 255)),
        Kind::Str => Style::default().fg(WARN),
        Kind::ChoiceStr | Kind::ChoiceInt => Style::default().fg(Color::Rgb(187, 154, 247)),
    }
}

fn row_line(label: &str, subtitle: Option<&str>, value_spans: Vec<Span<'static>>, selected: bool) -> ListItem<'static> {
    let label_style = if selected {
        Style::default().fg(Color::Black).add_modifier(Modifier::BOLD)
    } else {
        Style::default().fg(TEXT)
    };
    let mut spans = vec![Span::styled(format!("{:<34}", label), label_style)];
    spans.extend(value_spans);
    let mut lines = vec![Line::from(spans)];
    if let Some(sub) = subtitle {
        let sub_style = if selected { Style::default().fg(Color::Rgb(40, 40, 40)) } else { Style::default().fg(MUTED) };
        lines.push(Line::from(Span::styled(format!("  {sub}"), sub_style)));
    }
    let bg = if selected { Style::default().bg(ACCENT) } else { Style::default() };
    ListItem::new(lines).style(bg)
}

fn header_line(title: &str) -> ListItem<'static> {
    ListItem::new(Line::from(Span::styled(
        format!("── {title} ──"),
        Style::default().fg(ACCENT).add_modifier(Modifier::BOLD),
    )))
}

fn spacer() -> ListItem<'static> {
    ListItem::new(Line::from(""))
}

fn bool_spans(v: bool) -> Vec<Span<'static>> {
    if v {
        vec![Span::styled("● on", Style::default().fg(GOOD).add_modifier(Modifier::BOLD))]
    } else {
        vec![Span::styled("○ off", Style::default().fg(MUTED))]
    }
}

fn color_spans(text: &str) -> Vec<Span<'static>> {
    let mut spans = Vec::new();
    if let Some((r, g, b)) = blended_rgb(text) {
        spans.push(Span::styled("██ ", Style::default().fg(Color::Rgb(r, g, b))));
    }
    spans.push(Span::styled(text.to_string(), Style::default().fg(WARN)));
    spans
}

pub struct GroupView {
    pub title: &'static str,
    pub rows: Vec<(&'static str, &'static str, Vec<Span<'static>>)>,
}

impl crate::app::SettingsPage {
    pub fn groups_view(&self) -> Vec<GroupView> {
        self.groups
            .iter()
            .enumerate()
            .map(|(gi, g)| GroupView {
                title: g.title,
                rows: g
                    .specs
                    .iter()
                    .enumerate()
                    .map(|(si, spec)| {
                        let val = &self.values[gi][si];
                        let spans = spec_value_spans(spec, val);
                        (spec.label, spec.subtitle, spans)
                    })
                    .collect(),
            })
            .collect()
    }
}

fn spec_value_spans(spec: &crate::store::SettingSpec, val: &Value) -> Vec<Span<'static>> {
    if spec.is_color {
        return color_spans(val.as_str());
    }
    match spec.kind {
        Kind::Bool => bool_spans(val.as_bool()),
        _ => vec![Span::styled(val_display(val), value_style(spec.kind))],
    }
}

fn val_display(v: &Value) -> String {
    match v {
        Value::Bool(b) => b.to_string(),
        Value::Int(n) => n.to_string(),
        Value::Float(f) => format!("{f}"),
        Value::Str(s) => s.clone(),
    }
}

fn draw_settings_page(f: &mut Frame, groups: &[GroupView], selected: usize, area: Rect) {
    let mut items = Vec::new();
    let mut flat_index = 0usize;
    let mut highlight_offset = 0usize;
    for g in groups {
        items.push(header_line(g.title));
        for (i, (label, subtitle, spans)) in g.rows.iter().enumerate() {
            let is_sel = flat_index == selected;
            if is_sel {
                highlight_offset = items.len();
            }
            let sub = if subtitle.is_empty() { None } else { Some(*subtitle) };
            items.push(row_line(label, sub, spans.clone(), is_sel));
            flat_index += 1;
            let _ = i;
        }
        items.push(spacer());
    }
    let _ = highlight_offset;
    f.render_widget(List::new(items), area);
}

fn draw_appearance(f: &mut Frame, app: &App, area: Rect) {
    let p = &app.appearance;
    let mut items = Vec::new();
    let mut idx = 0usize;

    items.push(header_line(p.gaps_borders.title));
    for (i, spec) in p.gaps_borders.specs.iter().enumerate() {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::GapsBorders(x)) if x == i);
        let spans = spec_value_spans(spec, &p.gaps_borders.values[i]);
        let sub = if spec.subtitle.is_empty() { None } else { Some(spec.subtitle) };
        items.push(row_line(spec.label, sub, spans, sel));
        idx += 1;
    }
    items.push(spacer());

    items.push(header_line("Active border color (gradient)"));
    for (i, label) in ["Color 1", "Color 2 (optional)"].iter().enumerate() {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::BorderColor(x)) if x == i);
        let text = p.border.colors.get(i).cloned().unwrap_or_default();
        let spans = if text.is_empty() {
            vec![Span::styled("(none)", Style::default().fg(MUTED))]
        } else {
            color_spans(&text)
        };
        items.push(row_line(label, None, spans, sel));
        idx += 1;
    }
    {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::BorderAngle));
        items.push(row_line(
            "Gradient angle",
            None,
            vec![Span::styled(format!("{}°", p.border.angle), value_style(Kind::Int))],
            sel,
        ));
        idx += 1;
    }
    items.push(spacer());

    items.push(header_line("Inactive border"));
    {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::InactiveBorder));
        items.push(row_line(p.inactive_border.label, None, color_spans(p.inactive_border_val.as_str()), sel));
        idx += 1;
    }
    items.push(spacer());

    items.push(header_line(p.corners_opacity.title));
    for (i, spec) in p.corners_opacity.specs.iter().enumerate() {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::CornersOpacity(x)) if x == i);
        let spans = spec_value_spans(spec, &p.corners_opacity.values[i]);
        let sub = if spec.subtitle.is_empty() { None } else { Some(spec.subtitle) };
        items.push(row_line(spec.label, sub, spans, sel));
        idx += 1;
    }
    items.push(spacer());

    items.push(header_line(p.shadow.title));
    for (i, spec) in p.shadow.specs.iter().enumerate() {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::Shadow(x)) if x == i);
        let spans = spec_value_spans(spec, &p.shadow.values[i]);
        items.push(row_line(spec.label, None, spans, sel));
        idx += 1;
    }
    items.push(spacer());

    items.push(header_line(p.blur.title));
    for (i, spec) in p.blur.specs.iter().enumerate() {
        let sel = matches!(p.selected_ref(), Some(ApRowRef::Blur(x)) if x == i);
        let spans = spec_value_spans(spec, &p.blur.values[i]);
        items.push(row_line(spec.label, None, spans, sel));
        idx += 1;
    }
    let _ = idx;

    f.render_widget(List::new(items), area);
}

fn draw_animations(f: &mut Frame, app: &App, area: Rect) {
    let p = &app.animations;
    let mut items = Vec::new();
    items.push(row_line("Enable animations", None, bool_spans(p.enabled_val.as_bool()), p.selected == 0));
    items.push(spacer());
    items.push(header_line("Animation curves"));
    for (i, leaf) in p.leaves.iter().enumerate() {
        let sel = p.selected == i + 1;
        let mut spans = bool_spans(leaf.enabled);
        spans.push(Span::raw("  "));
        spans.push(Span::styled(format!("{:>5.2}", leaf.speed), value_style(Kind::Float)));
        let mut sub = format!("curve: {}", leaf.bezier);
        if !leaf.style.is_empty() {
            sub.push_str(&format!(" · style: {}", leaf.style));
        }
        items.push(row_line(&leaf.label, Some(&sub), spans, sel));
    }
    f.render_widget(List::new(items), area);
}

fn draw_monitors(f: &mut Frame, app: &App, area: Rect) {
    let mut lines: Vec<Line> = Vec::new();
    if let serde_json::Value::Array(list) = &app.monitors {
        for m in list {
            let name = m.get("name").and_then(|v| v.as_str()).unwrap_or("?");
            let desc = m.get("description").and_then(|v| v.as_str()).unwrap_or("");
            let w = m.get("width").and_then(|v| v.as_i64()).unwrap_or(0);
            let h = m.get("height").and_then(|v| v.as_i64()).unwrap_or(0);
            let hz = m.get("refreshRate").and_then(|v| v.as_f64()).unwrap_or(0.0);
            let x = m.get("x").and_then(|v| v.as_i64()).unwrap_or(0);
            let y = m.get("y").and_then(|v| v.as_i64()).unwrap_or(0);
            let scale = m.get("scale").and_then(|v| v.as_f64()).unwrap_or(1.0);
            let transform = m.get("transform").and_then(|v| v.as_i64()).unwrap_or(0);
            let focused = m.get("focused").and_then(|v| v.as_bool()).unwrap_or(false);
            let vrr = m.get("vrr").and_then(|v| v.as_bool()).unwrap_or(false);
            let ws = m
                .get("activeWorkspace")
                .and_then(|v| v.get("name"))
                .and_then(|v| v.as_str())
                .unwrap_or("-");

            let marker = if focused { Span::styled("● ", Style::default().fg(GOOD)) } else { Span::raw("○ ") };
            lines.push(Line::from(vec![
                marker,
                Span::styled(format!("{name}"), Style::default().fg(ACCENT).add_modifier(Modifier::BOLD)),
                Span::raw("  "),
                Span::styled(desc.to_string(), Style::default().fg(MUTED)),
            ]));
            lines.push(Line::from(format!(
                "    {w}x{h} @ {hz:.2}Hz · scale {scale} · pos {x},{y} · transform {transform} · workspace {ws}{}",
                if vrr { " · VRR" } else { "" }
            )));
            lines.push(Line::from(""));
        }
    }
    if lines.is_empty() {
        lines.push(Line::from(Span::styled("No monitors reported by hyprctl.", Style::default().fg(MUTED))));
    }
    lines.push(Line::from(""));
    lines.push(Line::from(Span::styled(
        "Arrangement (position/resolution/scale/rotation) is managed by nwg-displays —",
        Style::default().fg(MUTED),
    )));
    lines.push(Line::from(Span::styled(
        "run `nwg-displays` to drag-and-drop rearrange.",
        Style::default().fg(MUTED),
    )));
    f.render_widget(Paragraph::new(lines).wrap(Wrap { trim: false }), area);
}

fn draw_workspaces(f: &mut Frame, app: &App, area: Rect) {
    let mut lines: Vec<Line> = vec![Line::from(Span::styled(
        "Per-monitor assignment (config/workspaces.lua)",
        Style::default().fg(ACCENT).add_modifier(Modifier::BOLD),
    ))];
    for r in &app.workspaces {
        lines.push(Line::from(format!("  workspaces {}–{}  →  {}", r.start, r.end, r.monitor)));
    }
    if !app.workspace_specials.is_empty() {
        lines.push(Line::from(""));
        lines.push(Line::from(Span::styled("Special workspace rules", Style::default().fg(ACCENT).add_modifier(Modifier::BOLD))));
        for raw in &app.workspace_specials {
            let compact: String = raw.split_whitespace().collect::<Vec<_>>().join(" ");
            lines.push(Line::from(format!("  {compact}")));
        }
    }
    f.render_widget(Paragraph::new(lines).wrap(Wrap { trim: false }), area);
}

fn draw_keybinds(f: &mut Frame, app: &App, area: Rect) {
    let (list_area, search_area) = split_search(area, app.searching || !app.keybinds.search.is_empty());
    let filtered: Vec<_> = app
        .keybinds
        .items
        .iter()
        .enumerate()
        .filter(|(_, b)| matches_search(&app.keybinds.search, &crate::app::keybind_haystack(b)))
        .collect();
    let items: Vec<ListItem> = filtered
        .iter()
        .map(|(i, b)| {
            let sel = *i == app.keybinds.selected;
            let mut title = b.combo.clone();
            if !b.submap.is_empty() {
                title = format!("[{}] {}", b.submap, title);
            }
            let mut sub = b.action.clone();
            if !b.opts.is_empty() {
                sub.push_str(&format!("  [{}]", b.opts.split_whitespace().collect::<Vec<_>>().join(" ")));
            }
            row_line(&title, Some(&sub), vec![], sel)
        })
        .collect();
    let title = format!("{} keybinds — read-only, config/binds.lua", filtered.len());
    f.render_widget(Paragraph::new(Line::from(Span::styled(title, Style::default().fg(MUTED)))), Rect { height: 1, ..list_area });
    let list_area = Rect { y: list_area.y + 1, height: list_area.height.saturating_sub(1), ..list_area };
    let rel_selected = filtered.iter().position(|(i, _)| *i == app.keybinds.selected);
    let mut state = ListState::default().with_selected(rel_selected);
    f.render_stateful_widget(List::new(items), list_area, &mut state);
    if let Some(search_area) = search_area {
        draw_search_bar(f, &app.keybinds.search, app.searching, search_area);
    }
}

fn draw_autostart(f: &mut Frame, app: &App, area: Rect) {
    let (list_area, search_area) = split_search(area, app.searching || !app.autostart.search.is_empty());
    let filtered: Vec<_> = app
        .autostart
        .items
        .iter()
        .enumerate()
        .filter(|(_, a)| matches_search(&app.autostart.search, &crate::app::autostart_haystack(a)))
        .collect();
    let items: Vec<ListItem> = filtered
        .iter()
        .map(|(i, a)| {
            let sel = *i == app.autostart.selected;
            let sub = if a.comment.is_empty() { None } else { Some(a.comment.as_str()) };
            row_line(&a.command, sub, vec![], sel)
        })
        .collect();
    let rel_selected = filtered.iter().position(|(i, _)| *i == app.autostart.selected);
    let mut state = ListState::default().with_selected(rel_selected);
    f.render_stateful_widget(List::new(items), list_area, &mut state);
    if let Some(search_area) = search_area {
        draw_search_bar(f, &app.autostart.search, app.searching, search_area);
    }
}

fn draw_windowrules(f: &mut Frame, app: &App, area: Rect) {
    let (list_area, search_area) = split_search(area, app.searching || !app.windowrules.search.is_empty());
    let expanded_raw = app.expanded_rule.and_then(|i| app.windowrules.items.get(i)).map(|w| w.raw.clone());
    let raw_h = expanded_raw.as_ref().map(|r| (r.lines().count() as u16 + 2).min(list_area.height / 2)).unwrap_or(0);
    let split = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(3), Constraint::Length(raw_h)])
        .split(list_area);

    let filtered: Vec<_> = app
        .windowrules
        .items
        .iter()
        .enumerate()
        .filter(|(_, w)| matches_search(&app.windowrules.search, &crate::app::windowrule_haystack(w)))
        .collect();
    let items: Vec<ListItem> = filtered
        .iter()
        .map(|(i, w)| {
            let sel = *i == app.windowrules.selected;
            let mut sub = w.kind.clone();
            if !w.comment.is_empty() {
                sub.push_str(&format!(" · {}", w.comment));
            }
            row_line(&w.name, Some(&sub), vec![], sel)
        })
        .collect();
    let rel_selected = filtered.iter().position(|(i, _)| *i == app.windowrules.selected);
    let mut state = ListState::default().with_selected(rel_selected);
    f.render_stateful_widget(List::new(items), split[0], &mut state);

    if let Some(raw) = expanded_raw {
        let block = Block::default().borders(Borders::TOP).border_style(Style::default().fg(ACCENT_DIM));
        let inner = block.inner(split[1]);
        f.render_widget(block, split[1]);
        f.render_widget(
            Paragraph::new(raw).style(Style::default().fg(MUTED)).wrap(Wrap { trim: false }),
            inner,
        );
    }

    if let Some(search_area) = search_area {
        draw_search_bar(f, &app.windowrules.search, app.searching, search_area);
    }
}

fn matches_search(query: &str, haystack: &str) -> bool {
    query.is_empty() || haystack.to_lowercase().contains(&query.to_lowercase())
}

fn split_search(area: Rect, show: bool) -> (Rect, Option<Rect>) {
    if !show {
        return (area, None);
    }
    let split = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(1), Constraint::Min(1)])
        .split(area);
    (split[1], Some(split[0]))
}

fn draw_search_bar(f: &mut Frame, query: &str, active: bool, area: Rect) {
    let style = if active { Style::default().fg(ACCENT) } else { Style::default().fg(MUTED) };
    let cursor = if active { "▏" } else { "" };
    f.render_widget(
        Paragraph::new(Line::from(vec![Span::styled("/ ", style), Span::styled(format!("{query}{cursor}"), style)])),
        area,
    );
}
