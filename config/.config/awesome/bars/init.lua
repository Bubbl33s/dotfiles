---------------------------------------------
-- Bar assembly: one single joined awful.wibar per screen (left/middle/
-- right zones share one background, no gaps between them) -- matches the
-- pre-refactor look. A per-zone floating-pill layout was tried and reverted:
-- it made picom cast one large shadow across the whole transparent width
-- and made the middle zone's background stretch to fill leftover space
-- instead of hugging its content.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local left_bar   = require("bars.left")
local middle_bar = require("bars.middle")
local right_bar  = require("bars.right")

screen.connect_signal("request::desktop_decoration", function(s)
    -- Each screen has its own tag table (qtile groups: label 󰫤)
    awful.tag({ "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 " }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()

    local is_primary = (s == screen.primary)
    local colors = beautiful.palette

    local left_content   = left_bar.build_left(s)
    local middle_content = middle_bar.build_middle(s)
    local right_content  = right_bar.build_right(s, is_primary)

    -- qtile: bar height 30, opacity 0.95, margin [10, 15, 0, 15] on primary
    s.mywibox = awful.wibar {
        position = "top",
        screen   = s,
        height   = beautiful.wibar_height,
        bg       = colors.d .. "f2",
        shape    = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, beautiful.bar_radius) end,
        margins  = is_primary and {
            top   = beautiful.wibar_margin_top,
            left  = beautiful.wibar_margin_side,
            right = beautiful.wibar_margin_side,
        } or nil,
        widget   = {
            layout = wibox.layout.align.horizontal,
            left_content,
            middle_content,
            right_content,
        }
    }
end)
