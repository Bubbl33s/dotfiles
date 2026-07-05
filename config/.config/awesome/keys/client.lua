---------------------------------------------
-- Client keybindings and mouse bindings --
-- Pure relocation from rc.lua -- no behavior change.
---------------------------------------------

local awful = require("awful")

client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({ }, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ MODKEY }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ MODKEY }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)

client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        awful.key({ MODKEY }, "w", function (c) c:kill() end,
                  {description = "kill focused window", group = "client"}),
        awful.key({ MODKEY }, "f",
            function (c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end,
            {description = "toggle fullscreen", group = "client"}),
        awful.key({ MODKEY }, "t", function (c) c.floating = not c.floating end,
                  {description = "toggle floating", group = "client"}),
        awful.key({ MODKEY, "Shift" }, "m",
            function (c)
                c.maximized = not c.maximized
                c:raise()
            end,
            {description = "toggle maximized", group = "client"}),
        awful.key({ MODKEY }, "o", function (c) c:move_to_screen() end,
                  {description = "move to screen", group = "client"}),
    })
end)

-- Enable sloppy focus, so that focus follows mouse (qtile follow_mouse_focus)
client.connect_signal("mouse::enter", function(c)
    c:activate { context = "mouse_enter", raise = false }
end)
