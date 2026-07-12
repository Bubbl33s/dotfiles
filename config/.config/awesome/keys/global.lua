---------------------------------------------
-- Global keybindings: awesome, launcher, media, focus, move, resize, tag --
-- Pure relocation from rc.lua -- no behavior change.
---------------------------------------------

local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- General Awesome keys
awful.keyboard.append_global_keybindings({
    awful.key({ MODKEY,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ MODKEY, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ MODKEY, "Control" }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ MODKEY,           }, "Return", function () awful.spawn(TERMINAL) end,
              {description = "open a TERMINAL", group = "launcher"}),
    awful.key({ MODKEY            }, "r", function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
})

-- Application launchers (qtile)
awful.keyboard.append_global_keybindings({
    awful.key({ MODKEY            }, "b", function () awful.spawn("firefox") end,
              {description = "spawn web browser", group = "launcher"}),
    awful.key({ MODKEY            }, "m", function () awful.spawn("rofi -show apps") end,
              {description = "spawn rofi menu", group = "launcher"}),
    awful.key({ MODKEY, "Shift"   }, "m", function () awful.spawn("rofi -show") end,
              {description = "rofi window nav", group = "launcher"}),
    awful.key({ MODKEY, "Shift"   }, "s", function () awful.spawn("flameshot gui") end,
              {description = "screenshot", group = "launcher"}),
    awful.key({ MODKEY            }, "e", function () awful.spawn("thunar") end,
              {description = "spawn file manager", group = "launcher"}),
    awful.key({ MODKEY            }, "p", function () awful.spawn("/home/bubbles/.config/qtile/toggle_monitors.sh") end,
              {description = "toggle monitors", group = "screen"}),
    awful.key({ MODKEY            }, "space", function () KEYBOARD_LAYOUT:next_layout() end,
              {description = "next keyboard layout", group = "awesome"}),
})

-- Media keys (qtile)
awful.keyboard.append_global_keybindings({
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.spawn("pamixer -i 5") end,
              {description = "raise volume", group = "media"}),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.spawn("pamixer -d 5") end,
              {description = "lower volume", group = "media"}),
    awful.key({ }, "XF86AudioMute", function () awful.spawn("pamixer -t") end,
              {description = "toggle mute", group = "media"}),
    awful.key({ }, "XF86MonBrightnessUp", function () awful.spawn("brightnessctl set +10%") end,
              {description = "raise brightness", group = "media"}),
    awful.key({ }, "XF86MonBrightnessDown", function () awful.spawn("brightnessctl set 10%-") end,
              {description = "lower brightness", group = "media"}),
})

-- Focus related keybindings (qtile: h/l left-right, j up, k down)
-- global_bydirection only moves focus if there's a client in that exact
-- geometric direction (e.g. nothing "above" in a left/right split), so it
-- silently no-ops. Fall back to byidx cycling when that happens, so h/j/k/l
-- always land on the other visible client regardless of split orientation.
local function client_on_tag(c, t)
    if not t then return true end
    for _, ct in ipairs(c:tags()) do
        if ct == t then return true end
    end
    return false
end

-- Fullscreen games (Steam/Proton titles) commonly auto-minimize themselves
-- (WM_STATE: Iconic) when they lose input focus. awful.client.focus.* builds
-- its candidate list from screen.clients, which explicitly excludes
-- minimized clients ("technically not on the screen"), so h/j/k/l and
-- byidx silently skip them forever. Un-minimize the first minimized client
-- on the current tag as a last-resort fallback instead.
local function focus_minimized_on_tag()
    local s = awful.screen.focused()
    local t = s.selected_tag
    for _, c in ipairs(s.hidden_clients) do
        if c.minimized and client_on_tag(c, t) then
            c.minimized = false
            c:emit_signal("request::activate", "key.unminimize", {raise = true})
            return true
        end
    end
    return false
end

local function focus_direction(dir, fallback_idx)
    local c = client.focus
    awful.client.focus.global_bydirection(dir)
    if client.focus == c then
        awful.client.focus.byidx(fallback_idx)
    end
    if client.focus == c then
        focus_minimized_on_tag()
    end
end

awful.keyboard.append_global_keybindings({
    awful.key({ MODKEY }, "h", function () focus_direction("left", -1) end,
              {description = "focus left", group = "client"}),
    awful.key({ MODKEY }, "l", function () focus_direction("right", 1) end,
              {description = "focus right", group = "client"}),
    awful.key({ MODKEY }, "j", function () focus_direction("up", -1) end,
              {description = "focus up", group = "client"}),
    awful.key({ MODKEY }, "k", function () focus_direction("down", 1) end,
              {description = "focus down", group = "client"}),
    awful.key({ MODKEY, "Shift" }, "space", function ()
        local c = client.focus
        awful.client.focus.byidx(1)
        if client.focus == c then
            focus_minimized_on_tag()
        end
    end,
              {description = "focus next window", group = "client"}),
})

-- Move windows (qtile shuffle_*)
-- swap.global_bydirection always re-activates the original client at the end
-- (request::activate), so client.focus is unchanged whether the swap happened
-- or not -- can't use focus identity to detect a no-op. Compare geometry
-- instead: if the client didn't move, there was no neighbor in that exact
-- direction, so fall back to byidx swapping.
local function swap_direction(dir, fallback_idx)
    local c = client.focus
    if not c then return end
    local before = c:geometry()
    awful.client.swap.global_bydirection(dir)
    local after = c:geometry()
    if before.x == after.x and before.y == after.y then
        awful.client.swap.byidx(fallback_idx)
    end
end

awful.keyboard.append_global_keybindings({
    awful.key({ MODKEY, "Shift" }, "h", function () swap_direction("left", -1) end,
              {description = "move window left", group = "client"}),
    awful.key({ MODKEY, "Shift" }, "l", function () swap_direction("right", 1) end,
              {description = "move window right", group = "client"}),
    awful.key({ MODKEY, "Shift" }, "j", function () swap_direction("up", -1) end,
              {description = "move window up", group = "client"}),
    awful.key({ MODKEY, "Shift" }, "k", function () swap_direction("down", 1) end,
              {description = "move window down", group = "client"}),
})

-- Resize windows (qtile grow_left/right, shrink_main/grow_main)
awful.keyboard.append_global_keybindings({
    awful.key({ MODKEY, "Control" }, "h", function () awful.tag.incmwfact(-0.05) end,
              {description = "grow window left", group = "layout"}),
    awful.key({ MODKEY, "Control" }, "l", function () awful.tag.incmwfact(0.05) end,
              {description = "grow window right", group = "layout"}),
    awful.key({ MODKEY, "Control" }, "j", function () awful.client.incwfact(-0.05) end,
              {description = "shrink window", group = "layout"}),
    awful.key({ MODKEY, "Control" }, "k", function () awful.client.incwfact(0.05) end,
              {description = "grow window", group = "layout"}),
    awful.key({ MODKEY }, "n",
        function ()
            local t = awful.screen.focused().selected_tag
            if t then t.master_width_factor = 0.5 end
        end,
        {description = "reset window sizes", group = "layout"}),
    awful.key({ MODKEY }, "Tab", function () awful.layout.inc(1) end,
              {description = "next layout", group = "layout"}),
    awful.key({ MODKEY, "Shift" }, "Tab", function () awful.layout.inc(-1) end,
              {description = "previous layout", group = "layout"}),
})

-- Jump directly to a layout by index (awful.layout.layouts, see layouts.lua)
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { MODKEY, "Mod1" },
        keygroup    = "numrow",
        description = "jump to layout N",
        group       = "layout",
        on_press    = function (index)
            if awful.layout.layouts[index] then
                awful.layout.set(awful.layout.layouts[index])
            end
        end,
    },
})

-- Tags (qtile groups 1-9)
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { MODKEY },
        keygroup    = "numrow",
        description = "only view tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end,
    },
    awful.key {
        modifiers   = { MODKEY, "Control" },
        keygroup    = "numrow",
        description = "toggle tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },
    awful.key {
        modifiers   = { MODKEY, "Shift" },
        keygroup    = "numrow",
        description = "move focused client to tag and follow",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    -- qtile: togroup(..., switch_group=True)
                    client.focus:move_to_tag(tag)
                    tag:view_only()
                end
            end
        end,
    },
})
