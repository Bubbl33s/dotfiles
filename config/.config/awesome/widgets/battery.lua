---------------------------------------------
-- Battery widget: reads charge/status directly from --
-- /sys/class/power_supply/BAT*, no awful.spawn needed. --
-- Probes for the first available BAT* device at require-time; if none
-- exists, M.new() returns nil so callers skip it entirely (no empty box).
---------------------------------------------

local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local icons = require("theme.icons")

local M = {}

-- The charging glyph (bolt overlay) doesn't sit centered on its own advance
-- width the same way the plain battery glyph does -- keyed by charging
-- state since it's the SAME widget instance switching glyphs at runtime.
-- Px (via dpi), same as the other icon widgets' opts.pad_left/right, applied
-- through wibox.container.margin -- updated in place on every tick since
-- battery needs two distinct pad sets instead of one fixed opts table.
local PAD_CHARGING     = { left = dpi(5), right = dpi(0) }
local PAD_NOT_CHARGING = { left = dpi(7), right = dpi(0) }

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

-- Constructs the battery widget: icon on top, percentage label below --
-- stacked vertically since this widget only ever lives in the vertical
-- side bar now. Updated in place by a gears.timer. Returns nil when no
-- battery device is present so callers (bars/vertical.lua) can omit the
-- widget entirely.
function M.new()
    local battery_path = find_battery_path()
    if not battery_path then
        return nil
    end

    local battery_icon = wibox.widget {
        font   = beautiful.font,
        align  = "left",
        widget = wibox.widget.textbox,
    }
    local battery_icon_wrapped = wibox.widget {
        battery_icon,
        widget = wibox.container.margin,
    }
    local battery_pct = wibox.widget {
        font   = beautiful.font,
        align  = "center",
        widget = wibox.widget.textbox,
    }

    local function update()
        local capacity_raw = read_file(battery_path .. "/capacity")
        local status = read_file(battery_path .. "/status")
        local capacity = capacity_raw and tonumber(capacity_raw)

        if not capacity then
            return
        end

        local pad = (status == "Charging") and PAD_CHARGING or PAD_NOT_CHARGING
        battery_icon_wrapped.left = pad.left
        battery_icon_wrapped.right = pad.right
        battery_icon.text = battery_tier_icon(capacity, status)
        -- No "%" (redundant in a bar this narrow) and a smaller font at
        -- 100 (3 digits) -- at the normal size "100" doesn't fit the
        -- vertical bar's width and wraps onto a second line.
        local pct_text = tostring(capacity)
        battery_pct.text = pct_text
        battery_pct.font = (#pct_text == 3) and (beautiful.font_family .. " 9") or beautiful.font
    end

    gears.timer {
        timeout   = 5,
        autostart = true,
        call_now  = true,
        callback  = function()
            pcall(update)
        end,
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        battery_icon_wrapped,
        battery_pct,
    }
end

return M
