---------------------------------------------
-- Global tag pool (qtile groups): tags are shared across screens, not
-- per-screen. Exactly one screen may display a given tag at a time --
-- keys/global.lua swaps two screens' displayed tags instead of hiding one,
-- matching qtile's group-switch behavior on a multi-monitor setup.
---------------------------------------------

local awful = require("awful")

local M = {}
M.list = {}

local names = { "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 ", "󰫤 " }

-- Called once per screen from bars/init.lua's request::desktop_decoration
-- handler. First call creates the real global pool; later calls (a monitor
-- connected after startup, e.g. via autorandr) just hand that new screen
-- whichever tag isn't currently displayed anywhere.
function M.init(s)
    if #M.list > 0 then
        local shown = {}
        for other in screen do
            if other.selected_tag then
                shown[other.selected_tag] = true
            end
        end
        for _, t in ipairs(M.list) do
            if not shown[t] then
                t.screen = s
                t:view_only()
                break
            end
        end
        return
    end

    M.list = awful.tag(names, s, awful.layout.layouts[1])
end

return M
