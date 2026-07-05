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

local function volume_tier_icon(volume)
    if volume >= 66 then
        return icons.volume_high
    elseif volume >= 33 then
        return icons.volume_mid
    end
    return icons.volume_low
end

-- Constructs the volume widget: icon, a vertical level bar, and a
-- percentage label, stacked -- this widget only ever lives in the vertical
-- side bar now. Scroll up/down changes volume, click toggles mute -- same
-- `pamixer` flags/step already bound to the media keys (keys/global.lua),
-- kept here as ADJUST_STEP so both stay in sync if you tune it.
local ADJUST_STEP = 5

function M.new()
    local volume_icon = wibox.widget {
        font   = beautiful.font,
        align  = "center",
        widget = wibox.widget.textbox,
    }

    local level_bar = wibox.widget {
        max_value     = 100,
        value         = 0,
        forced_width  = dpi(6),
        forced_height = dpi(40),
        color         = beautiful.icon_bg,
        background_color = beautiful.palette.c5,
        widget        = wibox.widget.progressbar,
    }
    -- progressbar always draws horizontally (its own `vertical` property is
    -- a 4.0+ no-op) -- wibox.container.rotate is the documented way to turn
    -- it into a vertical bar. If the fill looks like it grows from the
    -- wrong end, swap "east" for "west" here.
    local level_bar_vertical = wibox.container.rotate(level_bar, "east")

    local volume_pct = wibox.widget {
        font   = beautiful.font,
        align  = "center",
        widget = wibox.widget.textbox,
    }

    local function update()
        read_command({ "pamixer", "--get-mute" }, function(muted)
            local ok = pcall(function()
                read_command({ "pamixer", "--get-volume" }, function(raw)
                    local inner_ok = pcall(function()
                        local volume = raw and tonumber(raw)
                        if not volume then
                            -- pamixer unavailable or no sink -- do not error
                            volume_icon.text = icons.mute
                            volume_pct.text = ""
                            level_bar.value = 0
                            return
                        end

                        level_bar.value = volume
                        volume_pct.text = volume .. "%"
                        volume_icon.text = (muted == "true") and icons.mute or volume_tier_icon(volume)
                    end)
                    if not inner_ok then
                        volume_icon.text = icons.mute
                    end
                end)
            end)
            if not ok then
                volume_icon.text = icons.mute
            end
        end)
    end

    gears.timer {
        timeout   = 2,
        autostart = true,
        call_now  = true,
        callback  = update,
    }

    local volume_widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        volume_icon,
        level_bar_vertical,
        volume_pct,
    }

    volume_widget:buttons({
        awful.button({}, 1, function() awful.spawn({ "pamixer", "-t" }); update() end),
        awful.button({}, 4, function() awful.spawn({ "pamixer", "-i", tostring(ADJUST_STEP) }); update() end),
        awful.button({}, 5, function() awful.spawn({ "pamixer", "-d", tostring(ADJUST_STEP) }); update() end),
    })

    return volume_widget
end

return M
