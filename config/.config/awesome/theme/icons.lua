---------------------------------------------
-- Nerdfont icon constants (placeholders) --
-- Every glyph below is intentionally left as an empty string. Fill in the
-- real nerdfont codepoint for each entry. Grouped by usage so filling them
-- in later is a single well-scoped pass.
---------------------------------------------

local icons = {}

-- Bar arrows / powerline separators (ported from qtile/resources/arrows.py)
icons.arrow_hard_right = ""
icons.arrow_soft_right = ""
icons.arrow_hard_left  = ""
icons.arrow_soft_left  = ""

-- Tags
icons.tag = "󰫤"

-- Distro glyph
icons.arch = "󰣇 "

-- Wifi signal tiers (0 = weakest signal .. 4 = strongest)
icons.wifi_0 = "󰤯"
icons.wifi_1 = "󰤟"
icons.wifi_2 = "󰤢"
icons.wifi_3 = "󰤥"
icons.wifi_4 = "󰤨"

-- Same tiers, wifi associated but internet check failed (mdi has a
-- dedicated wifi-strength-N-alert glyph per level for exactly this)
icons.wifi_0_no_internet = "󰤫"
icons.wifi_1_no_internet = "󰤠"
icons.wifi_2_no_internet = "󰤣"
icons.wifi_3_no_internet = "󰤦"
icons.wifi_4_no_internet = "󰤩"
icons.wired        = ""
icons.disconnected = "󰤮"
icons.wifi_no_internet = "󰤮"
icons.wired_no_internet = "󰈂"

-- Bluetooth tiers (widgets/bluetooth.lua): adapter off, adapter on but
-- nothing paired/connected, and a device actually connected
icons.bluetooth_off       = "󰂲"
icons.bluetooth_on        = "󰂯"
icons.bluetooth_connected = "󰂱"

-- Now-playing (widgets/mediaplayer.lua): bar glyph plus popup transport
-- controls, play/pause swapped per current playerctl status.
icons.music       = "󰝚 "
icons.music_play  = "󰐊"
icons.music_pause = "󰏤"
icons.music_prev  = "󰒮"
icons.music_next  = "󰒭"

-- Volume: up/down are plain Unicode triangles (not a Nerd Font PUA
-- codepoint) -- guaranteed to render in any font, no glyph-guessing risk,
-- used as the raise/lower click targets in widgets/volume.lua (which now
-- shows level via level_bar_vertical instead of a tiered speaker icon).
icons.volume_up   = "󰝝"
icons.volume_down = "󰝞"
icons.mute        = "󰝟"

-- Battery tiers, one per multiple of 10, plain and charging variants
icons.battery_10  = "󰁺"
icons.battery_20  = "󰁻"
icons.battery_30  = "󰁼"
icons.battery_40  = "󰁽"
icons.battery_50  = "󰁾"
icons.battery_60  = "󰁿"
icons.battery_70  = "󰂀"
icons.battery_80  = "󰂁"
icons.battery_90  = "󰂂"
icons.battery_100 = "󰁹"

icons.battery_10_charging  = "󰢜"
icons.battery_20_charging  = "󰂆"
icons.battery_30_charging  = "󰂇"
icons.battery_40_charging  = "󰂈"
icons.battery_50_charging  = "󰢝"
icons.battery_60_charging  = "󰂉"
icons.battery_70_charging  = "󰢞"
icons.battery_80_charging  = "󰂊"
icons.battery_90_charging  = "󰂋"
icons.battery_100_charging = "󰂅"

-- Extra: discharging and under 10% (more urgent than the battery_10
-- tier -- not connected to a charger at all)
icons.battery_critical = "󰂃"

-- Extra: plugged in, at 100%, done charging (distinct from
-- battery_100_charging, which is 100% while still actively charging)
icons.battery_full_charged = "󱈏"

-- Keyboard / calendar
icons.keyboard = " "
icons.calendar = "󰃭 "

-- Power menu trigger (widgets/power.lua)
icons.power = " "

-- Analog clock face, one glyph per hour (1..12), picked by the
-- current hour instead of a single static clock glyph
icons.clock_1  = "󱑋 "
icons.clock_2  = "󱑌 "
icons.clock_3  = "󱑍 "
icons.clock_4  = "󱑎 "
icons.clock_5  = "󱑏 "
icons.clock_6  = "󱑐 "
icons.clock_7  = "󱑑 "
icons.clock_8  = "󱑒 "
icons.clock_9  = "󱑓 "
icons.clock_10 = "󱑔 "
icons.clock_11 = "󱑕 "
icons.clock_12 = "󱑖 "

---------------------------------------------
-- App -> icon lookup for the focused-client tasklist (bars/left.lua), keyed
-- by the focused client's WM_CLASS. This does NOT hold its own glyph table:
-- it reads ~/.config/rofi/app-icons.map, the same file the rofi custom
-- launcher (nerdfont-launcher.py) uses -- one place to paste each glyph
-- instead of duplicating them here by hand. See that file's header for
-- the key|glyph[|class_override] format and matching rules.
---------------------------------------------

local APP_ICON_MAP_PATH = os.getenv("HOME") .. "/.config/rofi/app-icons.map"

local function normalize(s)
    return s:lower():gsub("[%s%-_.]", "")
end

local app_icon_entries -- lazily loaded: { {key, glyph, class_override}, ... }, longest key first
local app_icon_default = ""

local function load_app_icon_map()
    app_icon_entries = {}
    local file = io.open(APP_ICON_MAP_PATH, "r")
    if not file then return end

    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local key, glyph, override = line:match("^([^|]*)|?([^|]*)|?(.*)$")
            key = key and key:match("^%s*(.-)%s*$") or ""
            glyph = glyph and glyph:match("^%s*(.-)%s*$") or ""
            override = override and override:match("^%s*(.-)%s*$") or ""

            if key == "default" then
                app_icon_default = glyph
            elseif key ~= "" then
                table.insert(app_icon_entries, {
                    key     = normalize(key),
                    glyph   = glyph,
                    class   = override ~= "" and normalize(override) or nil,
                })
            end
        end
    end
    file:close()

    table.sort(app_icon_entries, function(a, b) return #a.key > #b.key end)
end

-- Resolve a Nerd Font glyph for a window's WM_CLASS via app-icons.map.
-- Tries the longest matching key first (see file header for the format).
function icons.app_icon(class)
    if not app_icon_entries then load_app_icon_map() end
    if not class then return app_icon_default end

    local norm_class = normalize(class)
    for _, entry in ipairs(app_icon_entries) do
        if entry.class == norm_class or norm_class:find(entry.key, 1, true) then
            return entry.glyph ~= "" and entry.glyph or app_icon_default
        end
    end
    return app_icon_default
end

return icons
