---------------------------------------------
-- Bar assembly: one horizontal awful.wibar per screen (left/right zones
-- share one background, no gap between them) -- matches the pre-refactor
-- look. A per-zone floating-pill layout was tried and reverted: it made
-- picom cast one large shadow across the whole transparent width. There
-- used to be a 3rd, middle zone (focused client icon + title); it's now
-- merged into bars/left.lua, so align.horizontal's middle slot is nil --
-- that still centers the (now empty) leftover space between the two zones.
-- Plus one vertical awful.wibar per screen (bars/vertical.lua) on the
-- right edge, same width as the horizontal bar's height, holding the
-- system status icons that used to live in the horizontal bar's right
-- zone (wifi, bluetooth, volume, battery, keyboard layout).
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local left_bar     = require("bars.left")
local right_bar    = require("bars.right")
local vertical_bar = require("bars.vertical")

screen.connect_signal("request::desktop_decoration", function(s)
    -- Each screen has its own tag table (qtile groups: label 󰫤)
    awful.tag({ "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 " }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()

    local is_primary = (s == screen.primary)
    local colors = beautiful.palette

    local left_content     = left_bar.build_left(s)
    local right_content    = right_bar.build_right(s)
    local vertical_content = vertical_bar.build_vertical(s, is_primary)

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
            nil,
            right_content,
        }
    }

    -- Same width as the horizontal bar's height ("same thickness"), full
    -- screen height by default for position="right". Margins mirror the
    -- horizontal bar's floating-pill look, just rotated (top/bottom/right
    -- instead of top/left/right).
    s.myverticalwibox = awful.wibar {
        position = "right",
        screen   = s,
        width    = beautiful.wibar_height,
        bg       = colors.d .. "f2",
        shape    = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, beautiful.bar_radius) end,
        margins  = is_primary and {
            top    = beautiful.wibar_margin_top,
            bottom = beautiful.wibar_margin_top,
            right  = beautiful.wibar_margin_side,
        } or nil,
        widget   = vertical_content,
    }

    -- Verified live via awesome-client: awful.wibar's own placement/stretch
    -- logic overrides the `width` given above at construction time,
    -- expanding it to nearly the full screen width instead of the 30px
    -- thickness requested (this is what caused the bar to render as wide
    -- horizontal stripes and left no reserved workarea space on the side).
    -- Re-asserting width right after construction re-triggers placement
    -- with the correct value and fixes both the rendering and the
    -- reserved tiling space.
    s.myverticalwibox.width = beautiful.wibar_height
end)
