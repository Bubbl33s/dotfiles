-- awesome_mode: api-level=4:screen=on
-- Ported from qtile config (~/.config/qtile/config.py):
-- same palette, powerline bar, keybindings and layout behavior.
--
-- This file is a thin entry point. See theme/, bars/, widgets/, keys/,
-- rules/ for the actual implementation, split by responsibility.

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
-- Dunst is the notification daemon: stub out naughty's D-Bus module so it
-- never competes for org.freedesktop.Notifications (naughty stays available
-- for awesome's own error popups below).
package.loaded["naughty.dbus"] = {}
local naughty = require("naughty")

-- {{{ Error handling
naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup!" or "!"),
        message = message
    }
end)
-- }}}

-- {{{ Variable definitions
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/init.lua")

TERMINAL = "alacritty"
EDITOR = os.getenv("EDITOR") or "nano"
EDITOR_CMD = TERMINAL .. " -e " .. EDITOR

MODKEY = "Mod4"
-- }}}

-- {{{ Wallpaper
screen.connect_signal("request::wallpaper", function(s)
    awful.wallpaper {
        screen = s,
        widget = {
            image                 = beautiful.wallpaper,
            resize                = true,
            upscale               = true,
            downscale             = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy   = "fit",
            widget                = wibox.widget.imagebox,
        },
    }
end)
-- }}}

-- {{{ Layouts (must be populated before bars/init.lua seeds tags with layouts[1])
require("layouts")
-- }}}

-- {{{ Bars (left/middle/right segments inside one awful.wibar per screen)
require("bars")
-- }}}

-- {{{ Key bindings
require("keys.global")
require("keys.client")
-- }}}

-- {{{ Rules
require("rules.client")
require("rules.notifications")
-- }}}

-- {{{ Autostart (qtile startup_once; picom & applets already run from ~/.xprofile)
awful.spawn.with_shell("setxkbmap -layout us,latam -option grp:win_space_toggle")
-- }}}
