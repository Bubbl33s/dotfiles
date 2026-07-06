---------------------------------------------
-- Powerline-style arrow/separator widgets --
-- Lua port of qtile/resources/arrows.py: each function returns a colored
-- glyph widget for stitching between two differently-colored bar segments
-- (foreground = incoming segment's color, background = outgoing segment's
-- color, matching the qtile TextBox foreground/background convention).
--
-- `direction` names which way the glyph's tip points: "left"/"right" render
-- straight from the font; "up"/"down" reuse the left/right glyph pair
-- rotated 90 degrees via wibox.container.rotate, since the font only ships
-- left/right codepoints, not up/down ones.
--
-- Rotation math (see /usr/share/awesome/lib/wibox/container/rotate.lua):
-- direction="east" on the container turns a west-pointing tip (left glyphs)
-- north (up), and an east-pointing tip (right glyphs) south (down) -- both
-- go through the SAME container rotation, only the base glyph differs.
-- A previous version paired "west" with left and "east" with right, which
-- cancels out to the same final direction for both -- that was the bug
-- where up/down looked identical.
---------------------------------------------

local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")

local M = {}

-- Own font size, independent of beautiful.font -- keeps every arrow glyph
-- visually consistent regardless of the theme's body text size (qtile:
-- DEFAULT_FONTSIZE = 33 in resources/arrows.py).
local DEFAULT_FONT = beautiful.font_family .. " 24"

-- up/down borrow the left/right glyph pair; up mirrors left's tip
-- (west), down mirrors right's tip (east) -- both then rotated the same
-- way (see rotation note above). If a live reload shows this mirrored,
-- flip this single "east" in `rotated()` to "west" -- do not touch this
-- table, the base-direction choice is what picks up vs down.
local BASE_DIRECTION = {
    left  = "left",
    right = "right",
    up    = "left",
    down  = "right",
}

local VERTICAL_DIRECTIONS = { up = true, down = true }

local SINGLE_ICONS = {
    left  = icons.arrow_hard_left,
    right = icons.arrow_hard_right,
}

local OUTLINED_ICONS = {
    left  = { icons.arrow_soft_left,  icons.arrow_hard_left  },
    right = { icons.arrow_hard_right, icons.arrow_soft_right },
}

-- fg/bg both go on the container.background: wibox.container.background
-- sets the cairo source to `fg` right before drawing its child (see
-- before_draw_children in wibox/container/background.lua), and
-- wibox.widget.textbox's draw() paints via cr:show_layout(), which uses
-- whatever source is already set -- so `fg` does correctly color the glyph
-- text, it does not need to be set on the textbox itself.
--
-- No forced_width/forced_height here -- that was tried to pin every tile to
-- the bar's own thickness, but the glyph's real Pango-measured width isn't
-- exactly that, so it padded the cell and separated the soft/hard pair (and
-- the arrow from its neighboring pill) instead of fixing anything. Left
-- auto-sized from the text, like before.
local function glyph(text, foreground, background, font)
    return wibox.widget {
        {
            text   = text,
            font   = font or DEFAULT_FONT,
            widget = wibox.widget.textbox,
        },
        fg     = foreground,
        bg     = background,
        widget = wibox.container.background,
    }
end

local function rotated(widget, direction)
    if VERTICAL_DIRECTIONS[direction] then
        return wibox.container.rotate(widget, "east")
    end
    return widget
end

function M.single_arrow(direction, foreground, background, font)
    local base = BASE_DIRECTION[direction]
    local widget = glyph(SINGLE_ICONS[base], foreground, background, font)
    return rotated(widget, direction)
end

-- Two-tone arrow (soft sliver + hard arrow), bundled as one widget so
-- callers can drop it straight into a layout without unpacking a pair.
function M.outlined_arrow(direction, foreground, background, font)
    local base = BASE_DIRECTION[direction]
    local pair = OUTLINED_ICONS[base]
    local widget = wibox.widget {
        glyph(pair[1], foreground, background, font),
        glyph(pair[2], foreground, background, font),
        layout = wibox.layout.fixed.horizontal,
    }
    return rotated(widget, direction)
end

return M
