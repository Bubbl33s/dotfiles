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

-- Constructs the volume widget: a wibox.widget.textbox updated in place by
-- a gears.timer, matching the polling-timer pattern used elsewhere.
function M.new()
    local volume_text = wibox.widget {
        font   = beautiful.font,
        widget = wibox.widget.textbox,
    }

    local function update()
        read_command({ "pamixer", "--get-mute" }, function(muted)
            local ok = pcall(function()
                if muted == "true" then
                    volume_text.text = icons.mute
                    return
                end

                read_command({ "pamixer", "--get-volume" }, function(raw)
                    local inner_ok = pcall(function()
                        local volume = raw and tonumber(raw)
                        if volume then
                            volume_text.text = volume_tier_icon(volume)
                        else
                            -- pamixer unavailable or no sink -- do not error, show mute glyph
                            volume_text.text = icons.mute
                        end
                    end)
                    if not inner_ok then
                        volume_text.text = icons.mute
                    end
                end)
            end)
            if not ok then
                volume_text.text = icons.mute
            end
        end)
    end

    gears.timer {
        timeout   = 2,
        autostart = true,
        call_now  = true,
        callback  = update,
    }

    return volume_text
end

return M
