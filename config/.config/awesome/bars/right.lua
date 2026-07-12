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
local segment = require("theme.segment")

local power_widget = require("widgets.power")
local mediaplayer_widget = require("widgets.mediaplayer")

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
local media_widget = mediaplayer_widget.new()

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
    local head_arrow = arrows.outlined_arrow("left", colors.d, colors.c4, beautiful.corner_arrow_font)
    local tail_arrow = arrows.outlined_arrow("right", colors.d, colors.c4)

    -- Pulls the power pill this many px closer to head_arrow -- negative
    -- shrinks head_arrow's own right edge, without touching its font size,
    -- to tighten the small color-wedge gap against the power pill's
    -- different bg (see theme/init.lua's corner_arrow_font note). Positive
    -- would push them apart instead. This one number is the whole knob.
    local HEAD_ARROW_NUDGE = dpi(-3)

    -- No `spacing` here on purpose: it used to be one value shared by every
    -- gap in the row. Now each segment.pill() call below carries its own
    -- `gap` option -- edit that number to change just that one space.
    local items = {
        layout = wibox.layout.fixed.horizontal,
    }

    items[#items + 1] = segment.pill({ media_widget }, { bg = beautiful.music_bg, gap = dpi(10), spacing = dpi(4) })
    items[#items + 1] = tail_arrow
    -- Space between tail_arrow and the layout-name pill -- edit this width.
    items[#items + 1] = segment.gap(dpi(10), colors.c4)

    items[#items + 1] = segment.pill({ s.mylayoutname }, { bg = beautiful.layoutname_bg, gap = dpi(10), spacing = dpi(0) })
    items[#items + 1] = segment.pill({
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
    }, { bg = beautiful.date_bg, gap = dpi(10), spacing = dpi(0) })
    items[#items + 1] = segment.pill({
        wibox.widget {
            layout  = wibox.layout.fixed.horizontal,
            spacing = dpi(4),
            time_icon,
            time_clock,
        },
    }, { bg = beautiful.time_bg, gap = dpi(10), spacing = dpi(0) })

    items[#items + 1] = wibox.widget {
        head_arrow,
        right  = HEAD_ARROW_NUDGE,
        widget = wibox.container.margin,
    }
    items[#items + 1] = segment.pill({ pow_widget }, { bg = beautiful.power_bg, spacing = dpi(0) })

    -- No right margin: the power pill above is the last item, and its own
    -- background should reach the bar's edge -- any final breathing room
    -- is segment.pill's own `pad` padding, not this outer margin.
    return wibox.widget {
        items,
        -- left  = dpi(0),
        right = dpi(-3),
        widget = wibox.container.margin,
    }
end

return M
