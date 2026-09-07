from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from .pages import (  # noqa: E402
    animations,
    appearance,
    autostart,
    input as input_page,
    keybinds,
    layout_misc,
    monitors,
    windowrules,
    workspaces,
)
from .pages.widgets import esc  # noqa: E402

PAGE_BUILDERS = [
    ("monitors", "Monitors", monitors.build_page),
    ("appearance", "Appearance", appearance.build_page),
    ("animations", "Animations", animations.build_page),
    ("input", "Input", input_page.build_page),
    ("layout_misc", "Layout & Misc", layout_misc.build_page),
    ("workspaces", "Workspaces", workspaces.build_page),
    ("keybinds", "Keybinds", keybinds.build_page),
    ("autostart", "Autostart", autostart.build_page),
    ("windowrules", "Window Rules", windowrules.build_page),
]


class MainWindow(Adw.ApplicationWindow):
    def __init__(self, app: Adw.Application):
        super().__init__(application=app, title="Hyprland Settings", default_width=1000, default_height=720)
        self.set_icon_name("preferences-desktop")

        self.toast_overlay = Adw.ToastOverlay()

        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE)
        self._titles: dict[str, str] = {}

        listbox = Gtk.ListBox(css_classes=["navigation-sidebar"])
        for key, title, builder in PAGE_BUILDERS:
            self._titles[key] = title
            try:
                page_widget = builder()
            except Exception as exc:  # keep the rest of the app usable if one page fails to build
                page_widget = _error_page(title, exc)
                icon_name = "dialog-error-symbolic"
            else:
                icon_name = getattr(page_widget, "get_icon_name", lambda: None)() or "preferences-other-symbolic"
            self.stack.add_named(page_widget, key)

            row = Adw.ActionRow(title=esc(title))
            row.add_prefix(Gtk.Image.new_from_icon_name(icon_name))
            row.set_name(key)
            listbox.append(row)

        listbox.connect("row-selected", self._on_row_selected)
        self.sidebar_listbox = listbox

        sidebar_header = Adw.HeaderBar(show_end_title_buttons=False)
        sidebar_toolbar = Adw.ToolbarView()
        sidebar_toolbar.add_top_bar(sidebar_header)
        sidebar_scroller = Gtk.ScrolledWindow(child=listbox)
        sidebar_toolbar.set_content(sidebar_scroller)
        sidebar_page = Adw.NavigationPage(title="Hyprland Settings", child=sidebar_toolbar)
        sidebar_page.set_size_request(240, -1)

        content_header = Adw.HeaderBar()
        content_toolbar = Adw.ToolbarView()
        content_toolbar.add_top_bar(content_header)
        content_toolbar.set_content(self.stack)
        self.content_page = Adw.NavigationPage(title=PAGE_BUILDERS[0][1], child=content_toolbar)

        split = Adw.NavigationSplitView(sidebar=sidebar_page, content=self.content_page)
        split.set_min_sidebar_width(220)
        split.set_max_sidebar_width(280)

        self.toast_overlay.set_child(split)
        self.set_content(self.toast_overlay)

        listbox.select_row(listbox.get_row_at_index(0))

    def _on_row_selected(self, _listbox, row):
        if row is None:
            return
        key = row.get_name()
        self.stack.set_visible_child_name(key)
        self.content_page.set_title(self._titles.get(key, "Hyprland Settings"))


def _error_page(title: str, exc: Exception) -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title=title)
    group = Adw.PreferencesGroup(title="This page failed to load")
    group.add(Adw.ActionRow(title=str(exc)))
    page.add(group)
    return page
