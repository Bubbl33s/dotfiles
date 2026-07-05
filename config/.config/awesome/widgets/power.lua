---------------------------------------------
-- Power widget: single icon that opens the usual power menu --
-- (Lock/Suspend/Reboot/Shutdown/Logout) via awful.menu. Styling comes
-- from beautiful's menu_* fields (theme/init.lua) -- no separate theme
-- table here, so restyling the menu means editing colors in one place.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

-- Width lives here, not in theme/init.lua's menu_* block: awful.menu only
-- reads a per-instance width from `args.theme.width` (passed below), NOT
-- from a top-level `args.width` -- that's why setting it used to silently
-- do nothing. beautiful.menu_width would still work as a fallback default
-- for OTHER menus, but this one overrides it directly.
local POWER_MENU_WIDTH = dpi(108)

-- Icon font size, separate from beautiful.font (12pt) so this glyph can be
-- tuned on its own without affecting every other plain-icon textbox in the
-- bar. "family + size" as one string is how wibox.widget.textbox.font works.
local POWER_ICON_FONT = beautiful.font_family .. " 14"

-- Single place to tune each action's command. No lock screen binary
-- (i3lock/betterlockscreen/...) is installed as of writing, so "Lock"
-- currently just tells logind the session is locked without actually
-- blanking/password-protecting the screen -- swap the command below once
-- you install one.
local ACTIONS = {
    { "lock",     "loginctl lock-session" },
    { "suspend",  "systemctl suspend" },
    { "reboot",   "systemctl reboot" },
    { "shutdown", "systemctl poweroff" },
    -- NOT `awesome.quit` directly: awful.menu invokes function-type cmds as
    -- cmd(item, self), passing the menu item table as arg #1. awesome.quit
    -- is a C function expecting an optional exit-code *number* there, so it
    -- throws "number expected, got table". Wrap it so the args get dropped.
    { "logout",   function() awesome.quit() end },
}

function M.new()
    local power_icon = wibox.widget {
        {
            {
                text   = icons.power,
                font   = POWER_ICON_FONT,
                widget = wibox.widget.textbox,
            },
            left   = dpi(2),
            right  = dpi(4),
            align  = "right",
            widget = wibox.container.margin,
        },
        bg     = beautiful.power_bg,
        widget = wibox.container.background,
    }

    local menu_items = {}
    for _, action in ipairs(ACTIONS) do
        local label, cmd = action[1], action[2]
        menu_items[#menu_items + 1] = {
            label,
            type(cmd) == "function" and cmd or function() awful.spawn(cmd) end,
        }
    end

    local power_menu = awful.menu({
        items = menu_items,
        theme = { width = POWER_MENU_WIDTH },
    })

    -- awful.menu has no shape/radius option of its own -- it's a plain
    -- wibox under the hood (menu.wibox), so round it the same way
    -- bars/init.lua rounds the wibar itself.
    power_menu.wibox.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, beautiful.menu_radius)
    end
    -- awful.menu defaults to opening at the mouse position, which lets it
    -- reach the bare screen edge -- the wibar itself never does that, it
    -- keeps beautiful.wibar_margin_side clear (bars/init.lua). Anchor the
    -- menu explicitly so its right edge lines up with the bar's own inset
    -- instead of the raw screen edge, and it drops from just under the bar.
    local function menu_coords()
        local s = awful.screen.focused()
        return {
            x = s.geometry.x + s.geometry.width - beautiful.wibar_margin_side - POWER_MENU_WIDTH,
            y = s.geometry.y + beautiful.wibar_margin_top + beautiful.wibar_height,
        }
    end

    power_icon:buttons({
        awful.button({}, 1, function()
            power_menu:toggle({ coords = menu_coords() })
        end),
    })

    return power_icon
end

return M
