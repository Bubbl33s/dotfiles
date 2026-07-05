---------------------------------------------
-- Vertical side bar: system status icons -- wifi, bluetooth, volume
-- (level bar + %), battery (%), keyboard layout. Moved out of the
-- horizontal bars/right.lua so the top bar isn't overloaded. Returns
-- plain content (no own background/shape) -- bars/init.lua's vertical
-- awful.wibar owns the background for this whole bar, same pattern as
-- the horizontal one.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local network_widget   = require("widgets.network")
local bluetooth_widget = require("widgets.bluetooth")
local volume_widget    = require("widgets.volume")
local battery_widget   = require("widgets.battery")

local M = {}

-- Keyboard layout is a shared, single-instance widget reused across every
-- screen's vertical bar -- same pattern as the other system-wide widgets
-- below (one state, reused wherever it's placed).
KEYBOARD_LAYOUT = awful.widget.keyboardlayout()

-- awful.widget.keyboardlayout shows the full xkb layout name ("latam"/
-- "us"), too wide for this dpi(30)-wide bar. There's no public API to
-- shorten it -- `self.layout_name` (the customization hook) is only
-- consulted once at construction time, before we'd get a chance to
-- override it -- so instead we mirror its text into our own short
-- display textbox. Cut to 2 chars ("la"/"us"); change `:sub(1, 2)` to
-- `:sub(1, 3)` below for "lat" instead.
local kb_short = wibox.widget {
    font   = beautiful.font_family_bold .. " 12",
    align  = "center",
    widget = wibox.widget.textbox,
}
local function sync_kb_short()
    local full = (KEYBOARD_LAYOUT.widget.text or ""):match("^%s*(.-)%s*$")
    kb_short.text = full:sub(1, 2)
end
KEYBOARD_LAYOUT.widget:connect_signal("widget::redraw_needed", sync_kb_short)
sync_kb_short()
-- Preserve the click-to-cycle-layout behavior awful.widget.keyboardlayout
-- normally binds to itself -- we're not displaying it directly anymore,
-- so that built-in button binding never fires unless mirrored here too.
kb_short:buttons({
    awful.button({}, 1, function() KEYBOARD_LAYOUT.next_layout() end),
})

-- Connectivity, bluetooth, volume, and battery are also single, shared,
-- system-wide widget instances -- one polling timer each, reused
-- wherever they're placed, instead of a duplicate timer per screen.
local net_widget = network_widget.new()
local bt_widget  = bluetooth_widget.new()
local vol_widget = volume_widget.new()
local bat_widget = battery_widget.new() -- may be nil -- no battery present

-- Same idea as bars/right.lua's bar_pill(), rotated: ONE shared rounded
-- background pill per group, stacked vertically, so the space between
-- widgets in a group is filled with `bg` instead of the bar's own color.
-- `gap` is the space BELOW this pill, before the next one (mirrors
-- bar_pill's `gap`, which is the space to the right in the horizontal bar).
local function vbar_pill(widgets, bg, gap)
    local inner_args = { layout = wibox.layout.fixed.vertical, spacing = dpi(6) }
    for _, w in ipairs(widgets) do
        inner_args[#inner_args + 1] = w
    end

    return wibox.widget {
        {
            wibox.widget(inner_args),
            left   = dpi(4),
            right  = dpi(4),
            top    = dpi(6),
            bottom = dpi(6) + (gap or 0),
            widget = wibox.container.margin,
        },
        bg     = bg or beautiful.icon_bg,
        shape  = function(cr, ww, hh) gears.shape.rounded_rect(cr, ww, hh, beautiful.icon_bg_radius) end,
        widget = wibox.container.background,
    }
end

-- Factory: builds the vertical bar content for screen `s`. `is_primary`
-- gates the wifi icon only, same convention bars/right.lua used to follow
-- (secondary screens omit it; volume/battery/bluetooth/keyboard are
-- system-wide and shown on every screen regardless).
function M.build_vertical(s, is_primary) -- luacheck: no unused
    local items = {
        layout  = wibox.layout.fixed.vertical,
        spacing = dpi(10),
    }

    if is_primary then
        items[#items + 1] = vbar_pill({ net_widget }, beautiful.icon_bg)
    end

    items[#items + 1] = vbar_pill({ bt_widget }, beautiful.icon_bg)
    items[#items + 1] = vbar_pill({ vol_widget }, beautiful.icon_bg)

    if bat_widget then
        items[#items + 1] = vbar_pill({ bat_widget }, beautiful.battery_bg)
    end

    items[#items + 1] = vbar_pill({ kb_short }, beautiful.kblayout_bg)

    return wibox.widget {
        items,
        top    = dpi(10),
        bottom = dpi(10),
        widget = wibox.container.margin,
    }
end

return M
