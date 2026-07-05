---------------------------------------------
-- Battery widget: reads charge/status directly from --
-- /sys/class/power_supply/BAT*, no awful.spawn needed. --
-- Probes for the first available BAT* device at require-time; if none
-- exists, M.new() returns nil so callers skip it entirely (no empty box).
---------------------------------------------

local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")

local M = {}

local function find_battery_path()
    for i = 0, 3 do
        local path = "/sys/class/power_supply/BAT" .. i
        local f = io.open(path .. "/capacity", "r")
        if f then
            f:close()
            return path
        end
    end
    return nil
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*l")
    f:close()
    return content
end

-- Picks one of the 22 tiered battery glyphs (theme/icons.lua):
--   status "Full"                -> battery_full_charged (done charging)
--   charging, any capacity       -> battery_<tier>_charging
--   discharging, capacity < 10   -> battery_critical
--   discharging, capacity >= 10  -> battery_<tier>
-- where <tier> rounds capacity to the nearest multiple of 10 (10..100).
local function battery_tier_icon(capacity, status)
    if status == "Full" then
        return icons.battery_full_charged
    end

    local charging = status == "Charging"

    if not charging and capacity < 10 then
        return icons.battery_critical
    end

    local tier = math.floor(capacity / 10 + 0.5) * 10
    tier = math.max(10, math.min(100, tier))

    return icons["battery_" .. tier .. (charging and "_charging" or "")]
end

-- Constructs the battery widget: a wibox.widget.textbox updated in place by
-- a gears.timer. Returns nil when no battery device is present so callers
-- (bars/right.lua) can omit the widget entirely.
function M.new()
    local battery_path = find_battery_path()
    if not battery_path then
        return nil
    end

    local battery_text = wibox.widget {
        font   = beautiful.font,
        widget = wibox.widget.textbox,
    }

    local function update()
        local capacity_raw = read_file(battery_path .. "/capacity")
        local status = read_file(battery_path .. "/status")
        local capacity = capacity_raw and tonumber(capacity_raw)

        if not capacity then
            return
        end

        battery_text.text = battery_tier_icon(capacity, status)
    end

    gears.timer {
        timeout   = 5,
        autostart = true,
        call_now  = true,
        callback  = function()
            pcall(update)
        end,
    }

    return battery_text
end

return M
