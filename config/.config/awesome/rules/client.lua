---------------------------------------------
-- Client rules (ruled.client): global + floating --
-- Pure relocation from rc.lua, plus rounded corners (task 5.1).
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local ruled = require("ruled")
local beautiful = require("beautiful")

local function rounded_client_shape(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, beautiful.client_radius)
end

ruled.client.connect_signal("request::rules", function()
    -- All clients will match this rule.
    ruled.client.append_rule {
        id         = "global",
        rule       = { },
        properties = {
            focus     = awful.client.focus.filter,
            raise     = true,
            screen    = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
            shape     = rounded_client_shape,
            -- Chromium/Electron apps (Brave included) restore their last
            -- window state on launch and often reopen with
            -- _NET_WM_STATE_MAXIMIZED_*. c.maximized overrides tiling
            -- layout geometry in awesome, so without this every such app
            -- opens "stuck" full-workarea instead of tiling normally.
            maximized = false,
        }
    }

    -- Floating clients (qtile float_rules + awesome defaults)
    ruled.client.append_rule {
        id       = "floating",
        rule_any = {
            instance = { "copyq", "pinentry" },
            class    = {
                "Arandr", "Blueman-manager", "Gpick", "Kruler", "Sxiv",
                "Tor Browser", "Wpa_gui", "veromix", "xtightvncviewer",
                "confirmreset", "makebranch", "maketag", "ssh-askpass",
                "cv2.imshow",
            },
            name    = {
                "Event Tester",  -- xev.
                "branchdialog",  -- gitk
                "pinentry",      -- GPG key password entry
            },
            role    = {
                "AlarmWindow",    -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true, ontop = true }
    }
end)

-- New clients become master by default (inserted at the top of the client
-- list), pushing the current master down. Push them to the end of the
-- stack instead, so opening a window never displaces what's already master.
client.connect_signal("manage", function(c)
    if not awesome.startup then
        c:to_secondary_section()
    end
end)

-- Fullscreen games (Steam/Proton) commonly auto-minimize themselves
-- (WM_STATE: Iconic) when they lose input focus -- see keys/global.lua for
-- the manual un-minimize fallback used while cycling focus. Restore them
-- automatically as soon as their tag is selected again, so switching back
-- doesn't just show the wallpaper. Scoped to c.fullscreen so it never
-- touches ordinary windows minimized on purpose (those aren't fullscreen).
tag.connect_signal("property::selected", function(t)
    if not t.selected then return end
    for _, c in ipairs(t:clients()) do
        if c.minimized and c.fullscreen then
            c.minimized = false
            c:emit_signal("request::activate", "tag.autorestore", {raise = true})
        end
    end
end)
