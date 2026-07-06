---------------------------------------------
-- Volume widget: polls `pamixer` for level and mute state --
-- Consistent with the existing media keybindings (keys/global.lua) that
-- already call `pamixer` for raise/lower/toggle-mute.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

-- awful.spawn.easy_async (non-blocking) instead of io.popen: io.popen blocks
-- Awesome's single-threaded main loop for as long as the subprocess takes,
-- same freeze-prone pattern fixed in widgets/network.lua.
local function read_command(cmd, cb)
    awful.spawn.easy_async(cmd, function(stdout)
        cb((stdout:gsub("%s+$", "")))
    end)
end

-- Constructs the volume widget: raise icon, a vertical level bar, lower
-- icon -- no percentage label, level is read off the bar itself. This
-- widget only ever lives in the vertical side bar now. Click the up/down
-- icons to raise/lower, click the bar to toggle mute; scroll anywhere in
-- the pill also raises/lowers (each child needs its OWN button binding --
-- clicks only hit the specific widget under the cursor, not its pill-mates
-- or a parent, same as bars/vertical.lua's kb_icon/kb_short). `pamixer`
-- flags/step already bound to the media keys (keys/global.lua), kept here
-- as ADJUST_STEP so both stay in sync if you tune it.
local ADJUST_STEP = 5

local ICON_FONT = beautiful.font_family .. " 14"

-- `opts.pad_left`/`opts.pad_right` (px, via dpi): nudges the glyph when
-- its ink isn't centered on its own advance width, via wibox.container.
-- margin.
function M.new(opts)
    opts = opts or {}

    local vol_up_icon = wibox.widget {
        text   = icons.volume_up,
        font   = ICON_FONT,
        align  = "left",
        widget = wibox.widget.textbox,
    }
    local vol_down_icon = wibox.widget {
        text   = icons.volume_down,
        font   = ICON_FONT,
        align  = "left",
        widget = wibox.widget.textbox,
    }

    local vol_up_wrapped = wibox.widget {
        vol_up_icon,
        left   = dpi(opts.pad_left or 0),
        right  = dpi(opts.pad_right or 0),
        widget = wibox.container.margin,
    }
    local vol_down_wrapped = wibox.widget {
        vol_down_icon,
        left   = dpi(opts.pad_left or 0),
        right  = dpi(opts.pad_right or 0),
        widget = wibox.container.margin,
    }

    -- Built by hand instead of wibox.widget.progressbar + wibox.container.
    -- rotate: that combination kept coming out wrong-axis (rotate's width/
    -- height swap plus the child's own forced size clamping is easy to get
    -- backwards, and did, twice). This is a plain background rectangle
    -- (level_bar_vertical, the empty/track color) containing a second one
    -- (`fill`, white) whose forced_height is set directly in px by
    -- set_level() below and bottom-anchored via wibox.container.place --
    -- no rotation, no axis ambiguity, grows straight up from the bottom.
    local BAR_WIDTH  = dpi(10)
    local BAR_HEIGHT = dpi(40)

    local fill = wibox.widget {
        forced_width  = BAR_WIDTH,
        forced_height = 0,
        bg            = beautiful.palette.w,
        widget        = wibox.container.background,
    }

    local level_bar_vertical = wibox.widget {
        {
            fill,
            valign = "bottom",
            widget = wibox.container.place,
        },
        forced_width  = BAR_WIDTH,
        forced_height = BAR_HEIGHT,
        bg            = beautiful.palette.c5,
        widget        = wibox.container.background,
    }

    local function set_level(pct)
        fill.forced_height = math.floor(BAR_HEIGHT * (math.max(0, math.min(100, pct)) / 100))
    end

    local function update()
        read_command({ "pamixer", "--get-mute" }, function(muted)
            local ok = pcall(function()
                read_command({ "pamixer", "--get-volume" }, function(raw)
                    local inner_ok = pcall(function()
                        local volume = raw and tonumber(raw)
                        if not volume then
                            -- pamixer unavailable or no sink -- do not error
                            set_level(0)
                            return
                        end

                        -- Muted shows as an empty bar -- no separate label
                        -- to switch to a mute glyph anymore.
                        set_level((muted == "true") and 0 or volume)
                    end)
                    if not inner_ok then
                        set_level(0)
                    end
                end)
            end)
            if not ok then
                set_level(0)
            end
        end)
    end

    gears.timer {
        timeout   = 2,
        autostart = true,
        call_now  = true,
        callback  = update,
    }

    local function raise() awful.spawn({ "pamixer", "-i", tostring(ADJUST_STEP) }); update() end
    local function lower() awful.spawn({ "pamixer", "-d", tostring(ADJUST_STEP) }); update() end
    local function toggle_mute() awful.spawn({ "pamixer", "-t" }); update() end

    vol_up_icon:buttons({
        awful.button({}, 1, raise),
        awful.button({}, 4, raise),
        awful.button({}, 5, lower),
    })
    vol_down_icon:buttons({
        awful.button({}, 1, lower),
        awful.button({}, 4, raise),
        awful.button({}, 5, lower),
    })
    level_bar_vertical:buttons({
        awful.button({}, 1, toggle_mute),
        awful.button({}, 4, raise),
        awful.button({}, 5, lower),
    })

    -- wibox.layout.fixed.vertical hands each child the FULL cross-axis
    -- width (the pill's width), not each child's own fit-preferred width --
    -- container.background paints that entire handed-down box, so without
    -- this wrap level_bar_vertical's forced_width (BAR_WIDTH) was ignored
    -- at draw time and it rendered as a wide bar instead of a thin one
    -- (the white `fill` inside stayed thin only because it already sat in
    -- its own place container). wibox.container.place uses the child's fit
    -- size instead of the available size, so this constrains the bar back
    -- to BAR_WIDTH, centered.
    local level_bar_centered = wibox.widget {
        level_bar_vertical,
        halign = "center",
        widget = wibox.container.place,
    }

    return wibox.widget {
        layout  = wibox.layout.fixed.vertical,
        spacing = dpi(6),
        vol_up_wrapped,
        level_bar_centered,
        vol_down_wrapped,
    }
end

return M
