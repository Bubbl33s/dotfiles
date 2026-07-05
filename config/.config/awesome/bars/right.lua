---------------------------------------------
-- Right bar zone: layout name, calendar/date, clock/time, power menu (in
-- that order). wifi/volume/battery/keyboard-layout/bluetooth moved out to
-- bars/vertical.lua. Returns plain content (no own background/shape) --
-- the single joined wibar in bars/init.lua owns the one shared background
-- for the whole bar.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi
local arrows = require("theme.arrows")

local power_widget = require("widgets.power")

local M = {}
local colors = beautiful.palette

-- Date and time as two separate textclocks so each can carry its own icon
-- (calendar / analog clock face) instead of one shared prefix.
local date_clock = wibox.widget.textclock("%Y-%m-%d %a", 60)
date_clock.font = beautiful.font_family_bold .. " 12"

local time_clock = wibox.widget.textclock("%H:%M", 60)
time_clock.font = beautiful.font_family_bold .. " 12"

-- Analog clock icon: one of 12 glyphs (theme/icons.lua's clock_1..clock_12),
-- picked by the current hour instead of a single static clock glyph.
local time_icon = wibox.widget {
    font   = beautiful.font,
    widget = wibox.widget.textbox,
}
local function update_time_icon()
    local hour = tonumber(os.date("%H"))
    local hour12 = hour % 12
    if hour12 == 0 then
        hour12 = 12
    end
    time_icon.text = icons["clock_" .. hour12]
end
update_time_icon()
gears.timer {
    timeout   = 60,
    autostart = true,
    call_now  = false,
    callback  = update_time_icon,
}

-- Power is also a single, shared, system-wide widget instance.
local pow_widget = power_widget.new()

-- Wraps one or more widgets in ONE shared rounded background pill, instead
-- of each getting its own separate pill -- giving each widget its own
-- background left a bar-colored gap between adjacent ones, since that gap
-- sat OUTSIDE any background container. Here the spacing between widgets is
-- the inner fixed.horizontal's `spacing`, which is INSIDE the shared
-- background, so it's filled with `bg` instead of the bar's own color.
-- `bg` defaults to beautiful.icon_bg; pass a different beautiful.*_bg field
-- (theme/init.lua) to give a group its own independent color.
-- `left`/`right`/`top`/`bottom` below are this group's own padding --
-- tune those (not bars/init.lua's outer margin) to control the space
-- between the pill's edge and its content.
-- `gap` is the space AFTER this pill, before the next one -- items in
-- build_right below no longer share one global spacing value, so this is
-- the one place per pill to change just that one gap.
-- IMPORTANT: `gap` is added to the RIGHT padding *inside* the background
-- container, not as a margin outside it -- a margin outside would be
-- transparent to whatever sits behind it (the bar's own dark bg), showing
-- as a mismatched stripe between pills. This way the gap is filled with
-- this same pill's `bg` color, exactly like the internal spacing between
-- multiple widgets grouped in one pill already is.
-- A plain solid-color spacer, same idea as the `gap` padding inside
-- bar_pill() above but for standalone widgets that aren't a pill (like
-- arrows.lua's separators) -- wibox.container.margin would leave this
-- transparent to the bar's own background instead of matching `bg`.
local function colored_gap(width, bg)
    return wibox.widget {
        forced_width = width,
        bg           = bg,
        widget       = wibox.container.background,
    }
end

local function bar_pill(widgets, bg, gap)
    local inner_args = { layout = wibox.layout.fixed.horizontal, spacing = dpi(10) }
    for _, w in ipairs(widgets) do
        inner_args[#inner_args + 1] = w
    end

    return wibox.widget {
        {
            wibox.widget(inner_args),
            left   = dpi(6),
            right  = dpi(6) + (gap or 0),
            top    = dpi(2),
            bottom = dpi(2),
            widget = wibox.container.margin,
        },
        bg     = bg or beautiful.icon_bg,
        shape  = function(cr, ww, hh) gears.shape.rounded_rect(cr, ww, hh, beautiful.icon_bg_radius) end,
        widget = wibox.container.background,
    }
end

-- Current layout name as text (qtile CurrentLayout)
local function build_layoutname(s)
    local tb = wibox.widget {
        font   = beautiful.font,
        widget = wibox.widget.textbox,
    }
    local function update()
        local l = awful.layout.get(s)
        tb.text = l and l.name or ""
    end
    awful.tag.attached_connect_signal(s, "property::selected", update)
    awful.tag.attached_connect_signal(s, "property::layout", update)
    update()
    return tb
end

-- Factory: builds the right segment for screen `s`.
function M.build_right(s)
    s.mylayoutname = build_layoutname(s)
    local head_arrow = arrows.outlined_left_arrow(colors.d, colors.c4)
    local tail_arrow = arrows.outlined_right_arrow(colors.d, colors.c4)

    -- No `spacing` here on purpose: it used to be one value shared by every
    -- gap in the row. Now each bar_pill() call below carries its own `gap`
    -- (3rd argument) -- edit that number to change just that one space.
    local items = {
        layout = wibox.layout.fixed.horizontal,
    }

    items[#items + 1] = tail_arrow
    -- Space between tail_arrow and the layout-name pill -- edit this width.
    items[#items + 1] = colored_gap(dpi(10), colors.c4)

    items[#items + 1] = bar_pill({ s.mylayoutname }, beautiful.layoutname_bg, dpi(10))
    items[#items + 1] = bar_pill({
        wibox.widget {
            layout  = wibox.layout.fixed.horizontal,
            spacing = dpi(4),
            wibox.widget {
                text   = icons.calendar,
                font   = beautiful.font,
                widget = wibox.widget.textbox,
            },
            date_clock,
        },
    }, beautiful.date_bg, dpi(10))
    items[#items + 1] = bar_pill({
        wibox.widget {
            layout  = wibox.layout.fixed.horizontal,
            spacing = dpi(4),
            time_icon,
            time_clock,
        },
    }, beautiful.time_bg, dpi(10))

    items[#items + 1] = head_arrow
    items[#items + 1] = bar_pill({ pow_widget }, beautiful.power_bg, 0)

    -- No right margin: the power pill above is the last item, and its own
    -- background should reach the bar's edge -- any final breathing room
    -- is bar_pill's own `right` padding, not this outer margin.
    return wibox.widget {
        items,
        left  = dpi(10),
        right = dpi(0),
        widget = wibox.container.margin,
    }
end

return M
