# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from libqtile import bar, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.widget import KeyboardLayout
from libqtile import hook
import subprocess

# base = lambda fg="text", bg="dark": {
#     "foreground": colors[fg],
#     "background": colors[bg],
# }

mod = "mod4"
terminal = guess_terminal()

@hook.subscribe.startup_once
def start_apps():
    subprocess.Popen(["setxkbmap -layout us,latam -option grp:win_space_toggle"])
    subprocess.Popen(["picom &"])
    subprocess.Popen(["systemctl restart NetworkManager"])
    subprocess.Popen(['Rblueman-applet'])

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "k", lazy.layout.down(), desc="Move focus down"),


    Key([mod, "shift"], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_down(), desc="Move window down"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.shrink_main(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_main(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn("alacritty"), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focuseqd window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(),desc="Spawn a command using a prompt widget"),

    # Browser
    Key([mod], "b", lazy.spawn("firefox"), desc="Spawn web browser"),

    # Menu
    Key([mod], "m", lazy.spawn("rofi -show drun"), desc="Spawn rofi menu"),
    Key([mod, "shift"], "m", lazy.spawn("rofi -show"), desc="Rofi window nav"),

    Key([mod], "space",  lazy.widget["keyboardlayout"].next_keyboard()),

    Key([mod, "shift"], "s", lazy.spawn("flameshot gui"), desc="Screenshot"),

    # Teclas multimedia para controlar el volumen
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5"), desc="Subir volumen"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5"), desc="Bajar volumen"),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t"), desc="Silenciar/Activar volumen"),

    # Teclas multimedia para controlar el brillo
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +10%"), desc="Aumentar brillo"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 10%-"), desc="Reducir brillo"),

    # Alternar entre los monitores y recargar Qtile
    Key([mod], "p", lazy.spawn("/home/bubbles/.config/qtile/toggle_monitors.sh")),

    Key([mod], "e", lazy.spawn("thunar"), desc="Spawn file system"),
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

groups = [Group(i) for i in [" ", " ", " ", " ", " ", " ", " ", " ", "󰊗 "]]

for i, group in enumerate(groups):
    actual_key = str(i + 1)

    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                actual_key,
                lazy.group[group.name].toscreen(),
                desc=f"Switch to group {group.name}",
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                actual_key,
                lazy.window.togroup(group.name, switch_group=True),
                desc=f"Switch to & move focused window to group {group.name}",
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod + shift + group number = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

colors = {
    "light": ["#e0bbd2", "#e0bbd2"],
    "dark": ["#13000a","#13000a"],
    "text": ["#cf91b5", "#cf91b5"],
    "color1": ["#bf6b99", "#bf6b99"],
    "color2": ["#b33b72", "#b33b72"],
    "color3": ["#8e3563", "#8e3563"],
    "color4": ["#572649", "#572649"],
}

layouts = [
    # layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    layout.MonadTall(margin=8, border_normal=colors["color4"], border_focus=colors["color2"], border_width=4),
    layout.MonadWide(margin=8, border_normal=colors["color4"], border_focus=colors["color2"], border_width=4),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
    layout.Max(margin=8, border_normal=colors["color4"], border_focus=colors["color2"], border_width=4),
]

widget_defaults = dict(
    font="UbuntuMono Nerd Font",
    fontsize=16,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    foreground=colors["light"],
                    background=colors["dark"],
                    font="UbuntuMono Nerd Font",
                    fontsize=19,
                    margin_y=3,
                    margin_x=0,
                    padding_y=8,
                    padding_x=5,
                    borderWidth=1,
                    active=colors["light"],
                    inactive=colors["color4"],
                    rounded=False,
                    highlight_method="block",
                    this_current_screen_border=colors["color2"],
                    this_screen_border=colors["color1"],
                    other_current_screen_border=colors["dark"],
                    other_screen_border=colors["dark"],
                ),
                widget.WindowName(
                    foreground=colors["color2"],
                    background=colors["dark"],
                    fontsize=13,
                    font="UbuntuMono Nerd Font Bold",
                ),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color1"], background=colors["dark"]),
                widget.Systray(padding=10, background=colors["color1"]),
                widget.Sep(padding=10, foreground=colors["color1"], background=colors["color1"]),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color2"], background=colors["color1"]),
                widget.Sep(padding=10, foreground=colors["color2"], background=colors["color2"]),
                widget.TextBox("󱚻 ", foreground=colors["light"], background=colors["color2"]),
                widget.Net(background=colors["color2"], interface='wlo1'),
                widget.Sep(padding=10, foreground=colors["color2"], background=colors["color2"]),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color3"], background=colors["color2"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                # widget.CurrentLayoutIcon(foreground=colors["light"], background=colors["color3"]),
                widget.CurrentLayout(foreground=colors["light"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                widget.TextBox(" ", foreground=colors["light"], background=colors["color3"]),
                widget.KeyboardLayout(font="UbuntuMono Nerd Font Bold", configured_keyboards=['us', 'latam'], foreground=colors["light"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color4"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color4"], background=colors["color4"]),
                widget.TextBox("󰃰 ", foreground=colors["light"], background=colors["color4"]),
                widget.Clock(
                    font="UbuntuMono Nerd Font Bold",
                    foreground=colors["light"],
                    background=colors["color4"],
                    format="%Y-%m-%d %a %H:%M"),
                widget.Sep(padding=10, foreground=colors["color4"], background=colors["color4"]),
            ],
            24,
            opacity=0.95,
        ),
        wallpaper="/home/bubbles/Pictures/bg/1338905.jpeg",
        wallpaper_mode="fill",
    ),
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    foreground=colors["light"],
                    background=colors["dark"],
                    font="UbuntuMono Nerd Font",
                    fontsize=19,
                    margin_y=3,
                    margin_x=5,
                    padding_y=8,
                    padding_x=5,
                    borderWidth=1,
                    active=colors["light"],
                    inactive=colors["color4"],
                    rounded=False,
                    highlight_method="block",
                    this_current_screen_border=colors["color2"],
                    this_screen_border=colors["color1"],
                    other_current_screen_border=colors["dark"],
                    other_screen_border=colors["dark"],
                ),
                widget.WindowName(
                    foreground=colors["color2"],
                    background=colors["dark"],
                    fontsize=13,
                    font="UbuntuMono Nerd Font Bold",
                ),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color3"], background=colors["dark"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                # widget.CurrentLayoutIcon(foreground=colors["light"], background=colors["color3"]),
                widget.CurrentLayout(foreground=colors["light"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                widget.TextBox(" ", foreground=colors["light"], background=colors["color3"]),
                widget.KeyboardLayout(font="UbuntuMono Nerd Font Bold", configured_keyboards=['us', 'latam'], foreground=colors["light"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color3"], background=colors["color3"]),
                widget.TextBox("◀", fontsize=32, padding=-4, foreground=colors["color4"], background=colors["color3"]),
                widget.Sep(padding=10, foreground=colors["color4"], background=colors["color4"]),
                widget.TextBox("󰃰 ", foreground=colors["light"], background=colors["color4"]),
                widget.Clock(
                    font="UbuntuMono Nerd Font Bold",
                    foreground=colors["light"],
                    background=colors["color4"],
                    format="%Y-%m-%d %a %H:%M"),
                widget.Sep(padding=10, foreground=colors["color4"], background=colors["color4"]),
            ],
            24,
            opacity=0.95,
        ),
        wallpaper="/home/bubbles/Pictures/bg/1338905.jpeg",
        wallpaper_mode="fill",
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class='cv2.imshow'),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
