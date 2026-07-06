---------------------------------------------
-- Vertical side bar: system status icons -- wifi, bluetooth, volume
-- (level bar + %), battery (%), keyboard layout. Moved out of the
-- horizontal bars/right.lua so the top bar isn't overloaded. Returns
-- plain content (no own background/shape) -- bars/init.lua's vertical
-- awful.wibar owns the background for this whole bar, same pattern as
-- the horizontal one.
---------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local arrows = require("theme.arrows")
local segment = require("theme.segment")
local icons = require("theme.icons")

local network_widget   = require("widgets.network")
local bluetooth_widget = require("widgets.bluetooth")
local volume_widget    = require("widgets.volume")
local battery_widget   = require("widgets.battery")

local M = {}
local colors = beautiful.palette

-- Per-element spacing, all in one place so each can be tuned without
-- hunting through the layout code below.
local GAPS = {
    -- Vertical wibar's top edge -> lead_arrow. 0 to match bars/right.lua's
    -- head_arrow -> power pill, which also touches directly (gap = 0
    -- there too).
    edge_to_arrow  = dpi(4),
    -- lead_arrow -> first icon pill. 0 to actually touch, same as
    -- edge_to_arrow's intent -- this is the one that was still showing a
    -- visible gap before: it, not edge_to_arrow, is what sits between the
    -- arrow and the wifi pill.
    arrow_to_first = dpi(0),
    -- Between consecutive icon pills.
    between_pills  = dpi(10),
    -- Last icon pill -> vertical wibar's bottom edge.
    bottom_margin  = dpi(10),
}

-- Per-icon horizontal padding, in px (dpi): pills are forced to the same
-- total width (theme/segment.lua), so every icon centers on the same
-- line -- but a few Nerd Font glyphs don't look centered on their OWN
-- advance width (ink leans left/right within their own bounding box).
-- Each icon widget wraps itself in wibox.container.margin to compensate
-- (widgets/network.lua, widgets/bluetooth.lua, widgets/volume.lua take
-- pad_left/pad_right opts; kb_icon below wraps itself the same way).
-- widgets/battery.lua has its own separate pad for charging vs not, since
-- that glyph pair's bearing differs by state, not just by widget.
local PADS = {
    net = { left = 4, right = 0 },
    bt  = { left = 6, right = 0 },
    vol = { left = 4, right = 0 },
    kb  = { left = 0, right = 0 },
}

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
local kb_icon = wibox.widget {
    text   = icons.keyboard,
    font   = beautiful.font,
    align  = "center",
    widget = wibox.widget.textbox,
}
local kb_icon_wrapped = wibox.widget {
    kb_icon,
    left   = dpi(PADS.kb.left),
    right  = dpi(PADS.kb.right),
    widget = wibox.container.margin,
}
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
-- Bound on BOTH kb_icon and kb_short: button events only hit the specific
-- widget under the cursor, not its pill-mates, so the icon needs its own
-- copy of this binding to also cycle on click.
local function next_layout() KEYBOARD_LAYOUT.next_layout() end
kb_icon:buttons({ awful.button({}, 1, next_layout) })
kb_short:buttons({ awful.button({}, 1, next_layout) })

-- Connectivity, bluetooth, volume, and battery are also single, shared,
-- system-wide widget instances -- one polling timer each, reused
-- wherever they're placed, instead of a duplicate timer per screen.
local net_widget = network_widget.new({ pad_left = PADS.net.left, pad_right = PADS.net.right })
local bt_widget  = bluetooth_widget.new({ pad_left = PADS.bt.left, pad_right = PADS.bt.right })
local vol_widget = volume_widget.new({ pad_left = PADS.vol.left, pad_right = PADS.vol.right })
local bat_widget = battery_widget.new() -- may be nil -- no battery present

-- Factory: builds the vertical bar content for screen `s`. `is_primary`
-- gates the wifi icon only, same convention bars/right.lua used to follow
-- (secondary screens omit it; volume/battery/bluetooth/keyboard are
-- system-wide and shown on every screen regardless).
function M.build_vertical(s, is_primary) -- luacheck: no unused
    -- Connects visually to bars/right.lua's head_arrow (same "left"/"up"
    -- glyph pair, same colors.d/colors.c4) -- placed OUTSIDE the margin
    -- below so it sits flush against the vertical wibar's own top edge,
    -- instead of picking up that margin's top gap like the icon pills do.
    -- Same beautiful.corner_arrow_font as bars/right.lua's head_arrow, so
    -- both corners match in size.
    local lead_arrow = arrows.outlined_arrow("up", colors.d, colors.c4, beautiful.corner_arrow_font)

    local items = {
        layout  = wibox.layout.fixed.vertical,
    }

    -- Groups to render, in order -- built as a plain list first so the last
    -- one (whichever it ends up being, depending on is_primary/bat_widget)
    -- can get `gap = 0` instead of every pill hardcoding its neighbor.
    local groups = {}

    if is_primary then
        groups[#groups + 1] = { { net_widget }, beautiful.icon_bg }
    end
    groups[#groups + 1] = { { bt_widget }, beautiful.icon_bg }
    groups[#groups + 1] = { { vol_widget }, beautiful.icon_bg }
    if bat_widget then
        groups[#groups + 1] = { { bat_widget }, beautiful.battery_bg }
    end
    groups[#groups + 1] = { { kb_icon_wrapped, kb_short }, beautiful.kblayout_bg }

    for i, group in ipairs(groups) do
        local widgets, bg = group[1], group[2]
        local gap = (i < #groups) and GAPS.between_pills or 0
        items[#items + 1] = segment.pill(widgets, {
            bg = bg, gap = gap, axis = "vertical", pad = dpi(6), cross = dpi(4), spacing = dpi(6),
        })
    end

    local rest = wibox.widget {
        items,
        top    = GAPS.arrow_to_first,
        bottom = GAPS.bottom_margin,
        widget = wibox.container.margin,
    }

    local arrow_wrapped = wibox.widget {
        lead_arrow,
        top    = GAPS.edge_to_arrow,
        widget = wibox.container.margin,
    }

    return wibox.widget {
        arrow_wrapped,
        rest,
        layout = wibox.layout.fixed.vertical,
    }
end

return M
