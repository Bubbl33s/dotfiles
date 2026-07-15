---------------------------------------------
-- Connectivity widget: wifi signal tier / wired indicator --
-- Replaces the old kB/s throughput widget. Detects the active interface via
-- `ip route show default` instead of hardcoding an interface name. Wifi
-- signal and overall internet reachability both come from `nmcli`
-- (NetworkManager now manages the wifi device directly on this machine).
-- Probed once at require-time. Never throws a Lua error -- falls back to
-- the disconnected glyph.
--
-- Icon selection, in priority order:
--   1. no active interface  -> icons.disconnected
--   2. wired                -> icons.wired / icons.wired_no_internet
--   3. wifi                 -> icons.wifi_0..4 (internet ok) or
--                               icons.wifi_0_no_internet..4_no_internet (no internet),
--                               picked by signal strength either way
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

-- One-time probe (not on every tick): is nmcli available?
local has_nmcli = os.execute("command -v nmcli >/dev/null 2>&1") == true

-- Parses the interface used for the current default route, e.g.:
-- "default via 192.168.1.1 dev wlo1 proto dhcp metric 600"
-- Runs via awful.spawn.easy_async (non-blocking) -- io.popen was blocking
-- Awesome's single-threaded main loop for as long as `ip`/`nmcli` took,
-- freezing tag switches/focus (and, transitively, everything else) for
-- multi-second stretches once a second.
local function get_active_interface(cb)
    awful.spawn.easy_async({ "ip", "route", "show", "default" }, function(stdout)
        cb(stdout:match("dev%s+(%S+)"))
    end)
end

-- Local sysfs existence check -- a plain file read, not a subprocess, so
-- keeping this synchronous is fine.
local function is_wireless(iface)
    if not iface then
        return false
    end
    local f = io.open("/sys/class/net/" .. iface .. "/wireless", "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Signal strength of the AP currently in use, from `nmcli`'s own wifi scan
-- list -- already a 0-100 percentage, no dBm conversion needed. The IN-USE
-- column marks the active connection with "*"; terse (-t) output separates
-- fields with ":".
local function get_wifi_signal(iface, cb)
    if not has_nmcli or not iface then
        cb(nil)
        return
    end
    awful.spawn.easy_async({ "nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list", "ifname", iface },
        function(stdout)
            local signal = stdout:match("%*:(%d+)")
            cb(signal and tonumber(signal) or nil)
        end)
end

-- Overall internet reachability, independent of wired/wifi or signal
-- strength. Relies on NetworkManager's own connectivity check (confirmed
-- active on this machine -- `nmcli -t -f CONNECTIVITY general` returns
-- "full"/"limited"/"portal"/"none"). If NM's connectivity checking were
-- ever disabled it would report "unknown" and we'd treat that as "no
-- internet" too, since we can't tell either way.
local function has_internet(cb)
    if not has_nmcli then
        cb(true) -- can't check -- don't claim "no internet" without evidence
        return
    end
    awful.spawn.easy_async({ "nmcli", "-t", "-f", "CONNECTIVITY", "general" }, function(stdout)
        local state = stdout:match("^%s*(.-)%s*$"):match("[^:]+$")
        cb(state == "full")
    end)
end

-- `online` picks between the plain tier glyphs and the mdi "-alert" variants
-- (wifi associated at this signal strength, but no internet behind it).
local function signal_tier_icon(signal, online)
    local tiers = online
        and { icons.wifi_0, icons.wifi_1, icons.wifi_2, icons.wifi_3, icons.wifi_4 }
        or { icons.wifi_0_no_internet, icons.wifi_1_no_internet, icons.wifi_2_no_internet,
             icons.wifi_3_no_internet, icons.wifi_4_no_internet }

    if signal >= 80 then
        return tiers[5]
    elseif signal >= 60 then
        return tiers[4]
    elseif signal >= 40 then
        return tiers[3]
    elseif signal >= 20 then
        return tiers[2]
    end
    return tiers[1]
end

-- Constructs the connectivity widget: a wibox.widget.textbox updated in
-- place by a gears.timer, matching the polling-timer pattern used by the
-- previous net_text widget in rc.lua.
--
-- `opts.pad_left`/`opts.pad_right` (px, via dpi): nudges the glyph via
-- wibox.container.margin when its ink isn't centered on its own advance
-- width, same reason as widgets/volume.lua.
function M.new(opts)
    opts = opts or {}

    local net_text = wibox.widget {
        font   = beautiful.font,
        align  = "left",
        widget = wibox.widget.textbox,
    }

    local function set_icon(text)
        net_text.text = text
    end

    local function update()
        get_active_interface(function(iface)
            local ok = pcall(function()
                if not iface then
                    set_icon(icons.disconnected)
                    return
                end

                local wired = not is_wireless(iface)

                has_internet(function(online)
                    local inner_ok = pcall(function()
                        if wired then
                            set_icon(online and icons.wired or icons.wired_no_internet)
                            return
                        end

                        get_wifi_signal(iface, function(signal)
                            local sig_ok = pcall(function()
                                set_icon(signal and signal_tier_icon(signal, online)
                                    or (online and icons.disconnected or icons.wifi_no_internet))
                            end)
                            if not sig_ok then
                                set_icon(icons.disconnected)
                            end
                        end)
                    end)
                    if not inner_ok then
                        set_icon(icons.disconnected)
                    end
                end)
            end)
            if not ok then
                set_icon(icons.disconnected)
            end
        end)
    end

    gears.timer {
        timeout   = 3,
        autostart = true,
        call_now  = true,
        callback  = update,
    }

    return wibox.widget {
        net_text,
        left   = dpi(opts.pad_left or 0),
        right  = dpi(opts.pad_right or 0),
        widget = wibox.container.margin,
    }
end

return M
