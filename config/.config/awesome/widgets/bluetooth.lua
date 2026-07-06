---------------------------------------------
-- Bluetooth widget: adapter power + connected-device state --
-- Same polling-timer shape as widgets/network.lua. Never throws a Lua
-- error -- falls back to the "off" glyph if bluetoothctl is unavailable
-- or something in the parse chain fails.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

-- One-time probe (not on every tick): is bluetoothctl available?
local has_bluetoothctl = os.execute("command -v bluetoothctl >/dev/null 2>&1") == true

local function get_powered(cb)
    if not has_bluetoothctl then
        cb(false)
        return
    end
    awful.spawn.easy_async({ "bluetoothctl", "show" }, function(stdout)
        cb(stdout:match("Powered:%s*(%a+)") == "yes")
    end)
end

local function get_connected(cb)
    awful.spawn.easy_async({ "bluetoothctl", "devices", "Connected" }, function(stdout)
        cb(stdout:match("%S") ~= nil)
    end)
end

local ICON_FONT = beautiful.font_family .. " 14"

-- Constructs the bluetooth widget: a wibox.widget.textbox updated in place
-- by a gears.timer.
--
-- `opts.pad_left`/`opts.pad_right` (px, via dpi): see the matching note in
-- widgets/network.lua.
function M.new(opts)
    opts = opts or {}

    local bt_text = wibox.widget {
        font   = ICON_FONT,
        align  = "left",
        widget = wibox.widget.textbox,
    }

    local function set_icon(text)
        bt_text.text = text
    end

    local function update()
        get_powered(function(powered)
            local ok = pcall(function()
                if not powered then
                    set_icon(icons.bluetooth_off)
                    return
                end

                get_connected(function(connected)
                    local inner_ok = pcall(function()
                        set_icon(connected and icons.bluetooth_connected or icons.bluetooth_on)
                    end)
                    if not inner_ok then
                        set_icon(icons.bluetooth_off)
                    end
                end)
            end)
            if not ok then
                set_icon(icons.bluetooth_off)
            end
        end)
    end

    gears.timer {
        timeout   = 5,
        autostart = true,
        call_now  = true,
        callback  = update,
    }

    return wibox.widget {
        bt_text,
        left   = dpi(opts.pad_left or 0),
        right  = dpi(opts.pad_right or 0),
        widget = wibox.container.margin,
    }
end

return M
