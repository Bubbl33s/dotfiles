---------------------------------------------
-- Left bar zone: Arch glyph + taglist + prompt box --
-- Returns plain content (no own background/shape) -- the single joined
-- wibar in bars/init.lua owns the one shared background for the whole bar.
---------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi
local arrows = require("theme.arrows")

local M = {}
local colors = beautiful.palette

-- Factory: builds the left zone content for screen `s`.
function M.build_left(s)
    local lead_arrow = arrows.outlined_right_arrow(colors.d, colors.c4)
    local tail_arrow = arrows.outlined_left_arrow(colors.d, colors.c4)

    local arch_glyph = wibox.widget {
        {
            {
                text   = icons.arch,
                font   = beautiful.font_family .. " 16",
                widget = wibox.widget.textbox,
            },
            left   = dpi(10),
            right  = dpi(4),
            widget = wibox.container.margin,
        },
        fg     = colors.l,
        bg     = colors.b,
        widget = wibox.container.background,
    }

    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = {
            awful.button({ }, 1, function(t) t:view_only() end),
            awful.button({ MODKEY }, 1, function(t)
                if client.focus then
                    client.focus:move_to_tag(t)
                end
            end),
            awful.button({ }, 3, awful.tag.viewtoggle),
            awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
            awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
        }
    }

    local taglist = wibox.widget {
        {
            s.mytaglist,
            left   = dpi(10),
            right  = dpi(10),
            widget = wibox.container.margin,
        },
        fg     = colors.l,
        bg     = colors.c4,
        widget = wibox.container.background,
    }

    return wibox.widget {
        {
            layout = wibox.layout.fixed.horizontal,
            arch_glyph,
            lead_arrow,
            taglist,
            -- wibox.container.margin(s.mypromptbox, dpi(10)),
            tail_arrow,
        },
        right  = dpi(10),
        widget = wibox.container.margin,
    }
end

return M
