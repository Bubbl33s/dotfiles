---------------------------------------------
-- Dark semi-gothic red/black/pastel-red theme --
-- (originally ported from qtile resources/colors.py DARK_RED_PASTEL_PALETTE,
-- refined darker/richer for the modular gothic theme refactor)
---------------------------------------------

local dpi = require("beautiful.xresources").apply_dpi

-- Single source of truth for all colors. Both `beautiful.*` fields below and
-- bar/widget modules (bars/*.lua, widgets/*.lua) read from this table --
-- no hardcoded hex literals should exist outside this file.
local colors = {
    w   = "#ffffff", -- white
    b   = "#000000", -- black
    l   = "#f2eaea", -- near-white text, softened for the gothic palette
    d   = "#050001", -- near-black background
    t   = "#cf91b5", -- pastel accent (minimized/secondary text)
    c_2 = "#b70803", -- bright red -- urgent/highlight accent (secondary)
    c_1 = "#e81509", -- bright red -- urgent/highlight accent
    c1  = "#7a1f20", -- dark red
    c2  = "#5c1717", -- darker red
    c3  = "#3f0f10", -- deep dark red
    c4  = "#300c0d",
    c5  = "#20080a", -- near-black red
}

local theme = {}

-- Expose the palette so bars/widgets can build segments with it
theme.palette = colors

theme.font          = "UbuntuMono Nerd Font 12"
theme.font_bold     = "UbuntuMono Nerd Font Bold 10"

-- Font family names without a baked-in point size, for widgets that need to
-- compose their own "family size" string dynamically (bars/*.lua).
theme.font_family      = "UbuntuMono Nerd Font"
theme.font_family_bold = "UbuntuMono Nerd Font Bold"

theme.bg_normal     = colors.d
theme.bg_focus      = colors.c2
theme.bg_urgent     = colors.c5
theme.bg_minimize   = colors.c4
theme.bg_systray    = colors.c1

theme.fg_normal     = colors.l
theme.fg_focus      = colors.l
theme.fg_urgent     = colors.l
theme.fg_minimize   = colors.t

-- qtile: layout margin=8, border_width=4
theme.useless_gap   = dpi(8)
theme.gap_single_client = true
theme.border_width  = dpi(4)
theme.border_color_normal = colors.c4
theme.border_color_active = colors.c2
theme.border_color_marked = colors.c5

-- Taglist (qtile GroupBox: highlight_method="text")
theme.taglist_font        = "UbuntuMono Nerd Font 14"
theme.taglist_fg_focus    = colors.l   -- current group
theme.taglist_fg_occupied = colors.c1  -- active (has windows)
theme.taglist_fg_empty    = colors.d   -- inactive
theme.taglist_fg_urgent   = colors.c_2
theme.taglist_bg_focus    = colors.c4
theme.taglist_bg_occupied = colors.c4
theme.taglist_bg_empty    = colors.c4
theme.taglist_bg_urgent   = colors.c4

-- Tasklist (qtile WindowName: only the focused window, text only)
theme.tasklist_font                 = "UbuntuMono Nerd Font Bold 10"
theme.tasklist_fg_focus             = colors.c2
theme.tasklist_bg_focus             = "#00000000"
theme.tasklist_plain_task_name      = true
theme.tasklist_disable_task_name    = false

theme.wallpaper = "/home/bubbles/Pictures/bg/1329229.png"

-- Rounded-corner radii shared by bar segment backgrounds (bars/*.lua) and
-- client windows (rules/client.lua). Kept modest -- flat powerline-style
-- theme, not heavily rounded. Tune visually once icon glyphs are filled in.
theme.bar_radius    = dpi(6)
theme.client_radius = dpi(8)

-- Pill backgrounds behind the right bar's grouped widgets (bar_pill() in
-- bars/right.lua). One color per group, all independently editable --
-- change any single one, or set them all to the same colors.cN for a
-- uniform look. icon_bg covers wifi+volume together as one shared pill
-- (that group IS meant to share a background); battery and power are each
-- their own pill with their own color, not shared with each other.
theme.icon_bg        = colors.c4 -- wifi+volume shared pill
theme.battery_bg     = colors.c4 -- battery pill
theme.power_bg       = colors.b -- power pill
theme.layoutname_bg  = colors.c4 -- "tile"/"floating" layout name pill
theme.kblayout_bg    = colors.c4 -- keyboard layout ("latam"/"us") pill
theme.date_bg        = colors.c4 -- calendar + date pill
theme.time_bg        = colors.c4 -- clock + time pill
theme.icon_bg_radius = dpi(6)    -- shared radius for all pills above

-- The wibar's own geometry (bars/init.lua's awful.wibar height + margins).
-- Named here, instead of inline literals in bars/init.lua, so anything
-- that needs to align to the bar's actual edges (e.g. widgets/power.lua's
-- menu, positioned to respect the same side margin instead of touching
-- the screen edge) reads the same single source of truth.
theme.wibar_height      = dpi(30)
theme.wibar_margin_top  = dpi(10)
theme.wibar_margin_side = dpi(15)

-- awful.menu reads these `menu_*` fields automatically from the active
-- beautiful theme, so any awful.menu built anywhere (e.g. widgets/power.lua)
-- already matches the palette without passing a per-menu theme table.
-- CUSTOMIZE HERE to restyle every menu in the config at once.
theme.menu_bg_normal    = colors.d
theme.menu_fg_normal    = colors.l
theme.menu_bg_focus     = colors.c2
theme.menu_fg_focus     = colors.l
theme.menu_border_color = colors.c4
theme.menu_border_width = dpi(1)
theme.menu_font         = theme.font_family_bold .. " 12"
theme.menu_height       = dpi(20)
-- No menu_width here on purpose: widgets/power.lua sets its own width
-- directly (POWER_MENU_WIDTH, passed as `theme = { width = ... }` on its
-- awful.menu call), which takes priority over any global fallback here
-- anyway -- so a menu_width in this file would just be dead weight.

-- NOT read automatically by awful.menu (it has no native shape/radius
-- option) -- widgets/power.lua applies this by hand to menu.wibox.shape.
-- Kept here anyway so every corner radius in the config (bar, clients,
-- menu) lives in one place.
theme.menu_radius = dpi(6)

return theme
