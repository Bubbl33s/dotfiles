---------------------------------------------
-- Middle bar zone: focused client app icon + truncated title --
-- Width AND height are capped so a long title truncates on one line
-- instead of resizing the bar or word-wrapping onto a second line.
-- Returns plain content (no own background/shape) -- the single joined
-- wibar in bars/init.lua owns the one shared background for the whole bar.
---------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

local MIDDLE_MAX_WIDTH  = dpi(420)
local MIDDLE_MAX_HEIGHT = dpi(20) -- ~one text line; without this, ellipsize
                                   -- still wraps onto a 2nd line if the bar
                                   -- is tall enough to fit it

local function resolve_app_icon(c)
    -- Trailing space forces pango to reserve extra width, otherwise the
    -- nerdfont glyph's right edge gets clipped inside the textbox.
    return icons.app_icon(c.class) .. " "
end

-- Factory: builds the middle zone content for screen `s`.
function M.build_middle(s)
    local colors = beautiful.palette

    s.mytasklist = awful.widget.tasklist {
        screen   = s,
        filter   = awful.widget.tasklist.filter.focused,
        -- Must be nested under `style`: tasklist.new() reads args.style (not
        -- a top-level args.fg_focus) and passes it to tasklist_label(), which
        -- wraps the title in <span color> markup that overrides the
        -- textbox's own fg property. This overrides theme.tasklist_fg_focus
        -- (colors.c2) for this bar only.
        style = { fg_focus = colors.l },
        widget_template = {
            {
                {
                    -- NOT "icon_role": awful.widget.common force-calls
                    -- :set_image() on whatever widget owns that id, which
                    -- this textbox (holding a nerdfont glyph, not a pixel
                    -- icon) does not implement.
                    id     = "app_icon_role",
                    font   = beautiful.font,
                    fg     = colors.l,
                    widget = wibox.widget.textbox,
                },
                {
                    -- No `fg` here: tasklist_label() renders the title as
                    -- <span color> markup driven by the fg_focus arg above,
                    -- which always wins over this textbox's own fg property.
                    id        = "text_role",
                    ellipsize = "end",
                    widget    = wibox.widget.textbox,
                },
                spacing = dpi(8),
                layout  = wibox.layout.fixed.horizontal,
            },
            id     = "background_role",
            widget = wibox.container.background,
            create_callback = function(self, c) -- luacheck: no unused
                self:get_children_by_id("app_icon_role")[1].text = resolve_app_icon(c)
            end,
            update_callback = function(self, c) -- luacheck: no unused
                self:get_children_by_id("app_icon_role")[1].text = resolve_app_icon(c)
            end,
        },
    }

    local constrained = wibox.widget {
        s.mytasklist,
        width    = MIDDLE_MAX_WIDTH,
        height   = MIDDLE_MAX_HEIGHT,
        strategy = "max",
        widget   = wibox.container.constraint,
    }

    local centered = wibox.container.place(constrained)
    centered.halign = "center"
    centered.valign = "center"

    return centered
end

return M
