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
local dpi = require("beautiful.xresources").apply_dpi

local left_bar     = require("bars.left")
local right_bar    = require("bars.right")
local vertical_bar = require("bars.vertical")
local tags         = require("tags")

-- Re-applies the primary-only margins/geometry to an already-built screen.
-- `request::desktop_decoration` fires synchronously from screen's C-level
-- `_added` handler (awful/screen.lua) -- on the very first screen, that can
-- run before X/awesome has attached "primary" to any output yet, so
-- `s == screen.primary` reads false at construction time even though the
-- screen ends up the (only, primary) one a moment later. Verified live:
-- one gears.timer.delayed_call tick (end of current glib iteration) was
-- NOT enough -- primary assignment lands even later. Rather than guess a
-- delay, `primary_changed` (fired whenever screen.primary actually settles
-- or changes, e.g. docking/undocking) re-derives is_primary and reapplies
-- just the margins/geometry bits below, on every screen, whenever that
-- happens -- correct regardless of how long the initial assignment takes.
local function apply_primary_geometry(s)
    if not (s.valid and s.mywibox and s.myverticalwibox) then return end

    local is_primary = (s == screen.primary)

    s.mywibox.margins = is_primary and {
        top   = beautiful.wibar_margin_top,
        left  = beautiful.wibar_margin_side,
        right = beautiful.wibar_margin_side,
    } or {}

    s.myverticalwibox.margins = is_primary and {
        right = beautiful.wibar_margin_side,
    } or {}

    s.myverticalwibox:geometry(is_primary and {
        y      = s.geometry.y + beautiful.wibar_vertical_margin_top,
        height = s.geometry.height - beautiful.wibar_vertical_margin_top - beautiful.wibar_margin_top - dpi(10),
    } or {
        y      = s.geometry.y,
        height  = s.geometry.height,
    })
end

screen.connect_signal("primary_changed", function()
    for s in screen do
        apply_primary_geometry(s)
    end
end)

screen.connect_signal("request::desktop_decoration", function(s)
    tags.init(s)

    s.mypromptbox = awful.widget.prompt()

    local is_primary = (s == screen.primary)
    local colors = beautiful.palette

    local left_content     = left_bar.build_left(s)
    local right_content    = right_bar.build_right(s)
    local vertical_content = vertical_bar.build_vertical(s, is_primary)

    -- Built first, ON PURPOSE, before s.mywibox below: awesome stacks same-
    -- layer windows (both of these are plain docks, no `ontop`) in creation
    -- order, later on top of earlier. `ontop = true` on the horizontal bar
    -- was tried instead, but that moves it into the always-on-top layer,
    -- which sits ABOVE fullscreen clients too -- not just above this dock.
    -- Creation order keeps both wibars in the normal dock layer (below
    -- fullscreen, above tiled/floating clients), just with the horizontal
    -- one stacked above the vertical one within that layer, covering the
    -- vertical bar's intentional top-edge overlap (wibar_vertical_margin_top
    -- in theme/init.lua) instead of leaving a visible seam.
    --
    -- Same width as the horizontal bar's height ("same thickness"). No
    -- `top`/`bottom` in margins on purpose -- confirmed live via
    -- awesome-client that awful.wibar unconditionally recomputes a
    -- left/right wibar's top/bottom margin from other wibars' raw
    -- `.height` (ignoring their own margins), discarding whatever we pass
    -- there. `stretch = false` disables the OTHER half of that same
    -- mechanism (the "maximize_vertically" placement that forces `height`
    -- to always span the full margins-derived range on every geometry
    -- change) -- without it, any `:geometry({ height = ... })` call below
    -- got silently reset back to the auto-computed full-height value.
    -- With stretch off, `y`/`height` become plain, directly settable
    -- geometry, same as `width` already is.
    s.myverticalwibox = awful.wibar {
        position = "right",
        screen   = s,
        width    = beautiful.wibar_height,
        stretch  = false,
        bg       = colors.d .. "f2",
        -- Top corners square, not rounded: they sit under the horizontal
        -- bar's intentional overlap (wibar_vertical_margin_top). Rounding
        -- them too left a tiny crack where BOTH bars' curves receded from
        -- the same corner, exposing the desktop behind instead of either
        -- bar's own color -- squaring this one off fills that gap.
        shape    = function(cr, w, h)
            gears.shape.partially_rounded_rect(cr, w, h, false, false, true, true, beautiful.bar_radius)
        end,
        margins  = is_primary and {
            right = beautiful.wibar_margin_side,
        } or nil,
        widget   = vertical_content,
    }

    -- qtile: bar height 30, opacity 0.95, margin [10, 15, 0, 15] on primary
    s.mywibox = awful.wibar {
        position = "top",
        screen   = s,
        height   = beautiful.wibar_height,
        bg       = colors.d .. "f2",
        shape    = function(cr, w, h) gears.shape.partially_rounded_rect(cr, w, h, true, true, false, true, beautiful.bar_radius) end,
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

    -- Verified live via awesome-client: awful.wibar's own placement/stretch
    -- logic overrides the `width` given above at construction time,
    -- expanding it to nearly the full screen width instead of the 30px
    -- thickness requested (this is what caused the bar to render as wide
    -- horizontal stripes and left no reserved workarea space on the side).
    -- Re-asserting width right after construction re-triggers placement
    -- with the correct value and fixes both the rendering and the
    -- reserved tiling space.
    s.myverticalwibox.width = beautiful.wibar_height

    -- Pushes the vertical bar's top down past the horizontal bar's own
    -- bottom edge (margin_top + height) plus one more margin_top gap, and
    -- shrinks its height to match, on primary screens -- otherwise (with
    -- `stretch` disabled) it would just keep the full-screen height from
    -- construction and run off the bottom edge instead of stopping
    -- wibar_margin_top short of it, same as the horizontal bar does.
    -- Delegated to apply_primary_geometry so `primary_changed` can redo it
    -- later without duplicating this logic.
    apply_primary_geometry(s)
end)
