---------------------------------------------
-- Powerline-style arrow/separator widgets --
-- Lua port of qtile/resources/arrows.py: each function returns a colored
-- glyph widget for stitching between two differently-colored bar segments
-- (foreground = incoming segment's color, background = outgoing segment's
-- color, matching the qtile TextBox foreground/background convention).
---------------------------------------------

local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")

local M = {}

-- Own font size, independent of beautiful.font -- keeps every arrow glyph
-- visually consistent regardless of the theme's body text size (qtile:
-- DEFAULT_FONTSIZE = 33 in resources/arrows.py).
local DEFAULT_FONT = beautiful.font_family .. " 24"

-- fg/bg both go on the container.background, not the inner textbox:
-- wibox.widget.textbox has no set_fg, so `fg` set there is a silent no-op
-- (falls back to a dead table field) -- only container.background actually
-- paints the color behind its children's text.
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

function M.single_left_arrow(foreground, background, font)
    return glyph(icons.arrow_hard_left, foreground, background, font)
end

-- Two-tone left arrow (soft sliver + hard arrow), bundled as one widget so
-- callers can drop it straight into a layout without unpacking a pair.
function M.outlined_left_arrow(foreground, background, font)
    return wibox.widget {
        glyph(icons.arrow_soft_left, foreground, background, font),
        glyph(icons.arrow_hard_left, foreground, background, font),
        layout = wibox.layout.fixed.horizontal,
    }
end

function M.outlined_right_arrow(foreground, background, font)
    return wibox.widget {
        glyph(icons.arrow_hard_right, foreground, background, font),
        glyph(icons.arrow_soft_right, foreground, background, font),
        layout = wibox.layout.fixed.horizontal,
    }
end

function M.single_left_flame(foreground, background, font)
    return glyph(icons.arrow_left_flame, foreground, background, font)
end

return M
