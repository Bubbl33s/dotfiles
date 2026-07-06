---------------------------------------------
-- Left bar zone: Arch glyph + taglist + prompt box + focused client's
-- app icon and truncated title (formerly its own middle bar zone --
-- merged in here since this config no longer uses a 3-zone layout).
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

-- Width AND height are capped so a long title truncates on one line
-- instead of growing the bar or word-wrapping onto a second line.
local TASKLIST_MAX_WIDTH  = dpi(420)
local TASKLIST_MAX_HEIGHT = dpi(20) -- ~one text line; without this, ellipsize
                                     -- still wraps onto a 2nd line if the bar
                                     -- is tall enough to fit it

local function resolve_app_icon(c)
    -- Trailing space forces pango to reserve extra width, otherwise the
    -- nerdfont glyph's right edge gets clipped inside the textbox.
    return icons.app_icon(c.class) .. " "
end

-- Factory: builds the left zone content for screen `s`.
function M.build_left(s)
    local lead_arrow = arrows.outlined_arrow("right", colors.d, colors.c4)
    local tail_arrow = arrows.outlined_arrow("left", colors.d, colors.c4)

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

    -- fixed.horizontal (below) gives every child the FULL row height, and
    -- the height="max" constraint here caps mytasklist well under that --
    -- without an explicit wibox.container.place + valign="center", the
    -- constrained box renders pinned to the TOP of that full height
    -- instead of vertically centered (the same pitfall as the keyboard
    -- layout widget in bars/right.lua).
    local tasklist_place = wibox.container.place(wibox.widget {
        s.mytasklist,
        width    = TASKLIST_MAX_WIDTH,
        height   = TASKLIST_MAX_HEIGHT,
        strategy = "max",
        widget   = wibox.container.constraint,
    })
    tasklist_place.halign = "left"
    tasklist_place.valign = "center"

    local tasklist_constrained = wibox.widget {
        tasklist_place,
        left   = dpi(8),
        widget = wibox.container.margin,
    }

    return wibox.widget {
        {
            layout = wibox.layout.fixed.horizontal,
            arch_glyph,
            lead_arrow,
            taglist,
            -- wibox.container.margin(s.mypromptbox, dpi(10)),
            tail_arrow,
            tasklist_constrained,
        },
        right  = dpi(10),
        widget = wibox.container.margin,
    }
end

return M
