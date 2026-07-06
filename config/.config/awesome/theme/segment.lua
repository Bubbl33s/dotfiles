---------------------------------------------
-- Shared "pill" builder for the bars -- one plain-background box wrapping
-- one or more widgets, used identically by bars/right.lua (horizontal) and
-- bars/vertical.lua (vertical). Replaces what used to be two near-identical,
-- separately-named functions (bar_pill / vbar_pill) with one shared API.
--
--   segment.pill(widgets, {
--       bg      = beautiful.icon_bg,  -- pill's own background color
--       axis    = "horizontal",       -- or "vertical" -- which way widgets stack
--       spacing = dpi(10),            -- space BETWEEN widgets inside this pill
--       pad     = dpi(6),             -- padding on the pill's main axis (left/right
--                                     -- for horizontal, top/bottom for vertical)
--       cross   = dpi(2),             -- padding on the cross axis (top/bottom for
--                                     -- horizontal, left/right for vertical)
--       gap     = dpi(10),            -- space AFTER this pill, before the next one
--       width   = beautiful.wibar_height, -- force the pill's OWN total width
--                                     -- (vertical axis only, see note below)
--   })
--
-- `width` (vertical axis only): without it, each pill sizes itself from its
-- content (icon glyph width varies per Nerd Font codepoint), so pills in the
-- vertical bar can end up with different total widths -- since they're all
-- left-anchored in that column, that makes their centered icons line up at
-- different x positions instead of a shared center line. Forcing every
-- vertical pill to the bar's own width fixes that at the source. Defaults
-- to beautiful.wibar_height when axis is "vertical".
--
-- `gap` is added to the trailing edge's padding *inside* the background
-- container, not as a margin outside it -- a margin outside would be
-- transparent to whatever sits behind it (the bar's own dark bg), showing
-- as a mismatched stripe between pills. This way the gap is filled with
-- this same pill's `bg` color, same as the internal `spacing` between
-- multiple widgets grouped in one pill.
---------------------------------------------

local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

function M.pill(widgets, opts)
    opts = opts or {}
    local vertical = opts.axis == "vertical"

    local inner_args = {
        layout  = vertical and wibox.layout.fixed.vertical or wibox.layout.fixed.horizontal,
        spacing = opts.spacing or dpi(10),
    }
    for _, w in ipairs(widgets) do
        inner_args[#inner_args + 1] = w
    end

    local pad   = opts.pad or dpi(6)
    local cross = opts.cross or dpi(2)
    local gap   = opts.gap or 0

    local margin_args = { wibox.widget(inner_args), widget = wibox.container.margin }
    if vertical then
        margin_args.left, margin_args.right   = cross, cross
        margin_args.top,  margin_args.bottom  = pad, pad + gap
    else
        margin_args.top,  margin_args.bottom  = cross, cross
        margin_args.left, margin_args.right   = pad, pad + gap
    end

    return wibox.widget {
        margin_args,
        bg     = opts.bg or beautiful.icon_bg,
        -- No `shape` here on purpose: a rounded pill on top of the bar's own
        -- differently-colored background always leaves its corners' outer
        -- triangle unpainted, showing the bar bg through as a small hole --
        -- plain rectangle avoids that.
        forced_width = vertical and (opts.width or beautiful.wibar_height) or nil,
        widget = wibox.container.background,
    }
end

-- NOTE: an earlier M.nudge() here wrapped a widget in wibox.container.margin
-- to shift it left/right. Removed -- inside the vertical bar's tightly-
-- packed pills it visibly corrupted the icon's render instead of just
-- shifting it (reproducible, root cause not fully pinned down). The
-- working replacement is padding the icon's own text with literal space
-- characters at the source (widgets/network.lua, widgets/bluetooth.lua,
-- widgets/volume.lua, widgets/battery.lua all take pad_left/pad_right
-- opts; bars/vertical.lua's kb_icon is padded directly). bars/right.lua's
-- HEAD_ARROW_NUDGE is a different, still-fine case: it shifts a whole
-- 2-glyph arrow widget, not a single centered icon textbox.

-- A plain solid-color spacer for standalone widgets that aren't a pill
-- (like arrows.lua's separators) -- wibox.container.margin would leave this
-- transparent to the bar's own background instead of matching a neighbor's
-- `bg`, showing as a mismatched stripe.
function M.gap(size, bg, axis)
    local args = { bg = bg, widget = wibox.container.background }
    if axis == "vertical" then
        args.forced_height = size
    else
        args.forced_width = size
    end
    return wibox.widget(args)
end

return M
