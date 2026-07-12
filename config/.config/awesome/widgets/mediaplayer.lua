---------------------------------------------
-- Now-playing widget: polls `playerctl` (MPRIS) for the active player's
-- track and exposes a popup with album art, track info, and prev/play-
-- pause/next transport controls. Bar content only (icon + scrolling
-- title) -- no own background, same convention as widgets/volume.lua and
-- widgets/network.lua; bars/right.lua wraps it in a segment.pill.
---------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

-- One-time probe (not on every tick): is playerctl available? Same
-- pattern as widgets/network.lua's has_nmcli.
local has_playerctl = os.execute("command -v playerctl >/dev/null 2>&1") == true

-- \x1f (unit separator) as the field separator: never appears in real
-- track metadata, unlike "-" or "|", so splitting can't be confused by an
-- artist/title/album that happens to contain the "normal" separators.
local METADATA_FORMAT = "{{status}}\x1f{{artist}}\x1f{{title}}\x1f{{album}}\x1f{{mpris:artUrl}}"

-- Which player wins when several MPRIS players exist (e.g. a YouTube tab
-- in brave + the Apple Music PWA in chromium): playerctl's --player list
-- is priority-ordered, %any falls back to whatever else is around. Base
-- names match their instances (chromium.instanceNNNN), and the same arg
-- goes to BOTH metadata polling and the transport controls so the buttons
-- always drive the player being displayed. Without this, playerctl just
-- uses whichever player registered on D-Bus first.
local PLAYER_PRIORITY = { "chromium", "%any" }
local PLAYER_ARG = "--player=" .. table.concat(PLAYER_PRIORITY, ",")

local IDLE_TEXT = "No media"

-- Fixed-width space for the scrolling title (dpi'd, see title_fixed below).
local MAX_TITLE_WIDTH = dpi(140)

local ICON_FONT = beautiful.font_family .. " 14"
local CONTROL_ICON_FONT = beautiful.font_family .. " 16"

-- Popup geometry: art block on the left, info column (title/artist/album/
-- controls) on the right. INFO_WIDTH is derived so the info column always
-- fills exactly what's left of the fixed popup width -- long titles can
-- wrap/ellipsize against it instead of stretching the popup.
local POPUP_WIDTH = dpi(340)
local POPUP_MARGIN = dpi(10)
local ART_SIZE = dpi(110)
local ART_INFO_SPACING = dpi(10)
local INFO_WIDTH = POPUP_WIDTH - 2 * POPUP_MARGIN - ART_SIZE - ART_INFO_SPACING

-- Static path is fine here: only ever one now-playing widget/session, and
-- each fetch overwrites it -- no need for a per-track unique name.
local ART_CACHE_PATH = "/tmp/awesome-mediaplayer-art.jpg"

-- Splits on a literal (non-magic) separator char while preserving empty
-- fields (e.g. no artist tag) -- plain gmatch("[^sep]+") would silently
-- drop those instead of returning "".
local function split_fields(str, sep)
    local parts = {}
    for part in (str .. sep):gmatch("(.-)" .. sep) do
        parts[#parts + 1] = part
    end
    return parts
end

function M.new()
    local icon_widget = wibox.widget {
        text   = icons.music,
        font   = ICON_FONT,
        widget = wibox.widget.textbox,
    }

    local title_textbox = wibox.widget {
        text   = IDLE_TEXT,
        font   = beautiful.font,
        widget = wibox.widget.textbox,
    }

    local title_scroll = wibox.widget {
        layout        = wibox.container.scroll.horizontal,
        max_size      = MAX_TITLE_WIDTH,
        speed         = 40,
        fps           = 10,
        step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
        title_textbox,
    }

    -- scroll:fit() returns min(text_width, max_size) -- a short title
    -- would otherwise shrink this widget (and the pill around it) instead
    -- of holding the "controlled fixed space" asked for, so the outer
    -- size is forced here rather than left to scroll's own sizing.
    local title_fixed = wibox.widget {
        title_scroll,
        strategy = "exact",
        width    = MAX_TITLE_WIDTH,
        widget   = wibox.container.constraint,
    }

    -- Popup contents -----------------------------------------------------

    local popup_art = wibox.widget {
        resize        = true,
        forced_width  = ART_SIZE,
        forced_height = ART_SIZE,
        -- Rounded like the bar pills/menu so the art block matches the
        -- config's shape language.
        clip_shape    = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.bar_radius)
        end,
        widget        = wibox.widget.imagebox,
    }
    -- Long titles wrap to multiple lines against the exact-width info
    -- column (no marquee -- the popup grows vertically instead, which
    -- awful.popup handles since only the width is pinned).
    local popup_title = wibox.widget {
        text   = IDLE_TEXT,
        font   = beautiful.font_family_bold .. " 12",
        align  = "center",
        wrap   = "word_char",
        widget = wibox.widget.textbox,
    }

    -- Artist/album stay single-line -- they ellipsize against the
    -- exact-width info column instead.
    local popup_artist = wibox.widget {
        font      = beautiful.font,
        align     = "center",
        ellipsize = "end",
        widget    = wibox.widget.textbox,
    }
    local popup_album = wibox.widget {
        font      = beautiful.font,
        align     = "center",
        ellipsize = "end",
        widget    = wibox.widget.textbox,
    }

    -- Rounded pill behind each transport control (bg from the theme's
    -- music_* fields, hover feedback to palette.c2). Returns the pill and
    -- the inner textbox -- the play/pause icon still needs text updates
    -- from set_idle/set_playing.
    local function control_button(icon_text, bg_color)
        local icon = wibox.widget {
            text   = icon_text,
            font   = CONTROL_ICON_FONT,
            align  = "center",
            widget = wibox.widget.textbox,
        }
        local button = wibox.widget {
            {
                icon,
                left   = dpi(10),
                right  = dpi(10),
                top    = dpi(2),
                bottom = dpi(2),
                widget = wibox.container.margin,
            },
            bg    = bg_color,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, beautiful.bar_radius)
            end,
            widget = wibox.container.background,
        }
        button:connect_signal("mouse::enter", function() button.bg = beautiful.palette.c2 end)
        button:connect_signal("mouse::leave", function() button.bg = bg_color end)
        return button, icon
    end

    local prev_button = control_button(icons.music_prev, beautiful.music_button_bg)
    local playpause_button, playpause_icon = control_button(icons.music_play, beautiful.music_accent)
    local next_button = control_button(icons.music_next, beautiful.music_button_bg)

    -- Info column: exact width so long text truncates/scrolls against it
    -- (a plain fixed.vertical would let the widest child stretch the popup).
    local popup_info = wibox.widget {
        {
            layout  = wibox.layout.fixed.vertical,
            spacing = dpi(6),
            popup_title,
            -- Artist in the theme's bright-red accent (c_1); album stays on
            -- the popup's default fg. Deliberately NOT palette.t -- that
            -- pastel pink is foreign to the red/black look of everything
            -- else on screen (its only other use is fg_minimize).
            { popup_artist, fg = beautiful.palette.c1, widget = wibox.container.background },
            popup_album,
            {
                {
                    layout  = wibox.layout.fixed.horizontal,
                    spacing = dpi(12),
                    prev_button,
                    playpause_button,
                    next_button,
                },
                halign = "center",
                widget = wibox.container.place,
            },
        },
        strategy = "exact",
        width    = INFO_WIDTH,
        widget   = wibox.container.constraint,
    }

    local popup = awful.popup {
        ontop  = true,
        visible = false,
        -- min == max pins the popup to a truly fixed width (awful.popup
        -- has no plain `width` arg -- it sizes to content otherwise, and
        -- INFO_WIDTH's derivation assumes this exact total).
        minimum_width = POPUP_WIDTH,
        maximum_width = POPUP_WIDTH,
        bg     = beautiful.menu_bg_normal,
        border_color = beautiful.menu_border_color,
        border_width = beautiful.menu_border_width,
        -- awful.popup DOES support `shape` natively (unlike awful.menu,
        -- see widgets/power.lua's note on menu.wibox.shape) -- still the
        -- same beautiful.menu_radius so every rounded corner in the config
        -- stays driven by that one value.
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.menu_radius)
        end,
        widget = {
            {
                -- Art alone on the left, info column on the right; both
                -- vertically centered against each other.
                { popup_art, valign = "center", widget = wibox.container.place },
                { popup_info, valign = "center", widget = wibox.container.place },
                layout  = wibox.layout.fixed.horizontal,
                spacing = ART_INFO_SPACING,
            },
            margins = POPUP_MARGIN,
            widget  = wibox.container.margin,
        },
    }

    -- Anchored under the wibar like widgets/power.lua's menu_coords, but
    -- centered on the click point instead of the bar's fixed right edge --
    -- this widget doesn't live at a fixed screen x. Clamped so it never
    -- runs off either side of the screen.
    local function popup_coords()
        local s = awful.screen.focused()
        local x = mouse.coords().x - POPUP_WIDTH / 2
        local min_x = s.geometry.x + beautiful.wibar_margin_side
        local max_x = s.geometry.x + s.geometry.width - beautiful.wibar_margin_side - POPUP_WIDTH
        x = math.max(min_x, math.min(x, max_x))
        return {
            x = x,
            y = s.geometry.y + beautiful.wibar_margin_top + beautiful.wibar_height,
        }
    end

    local function toggle_popup()
        if popup.visible then
            popup.visible = false
            return
        end
        local coords = popup_coords()
        popup.x = coords.x
        popup.y = coords.y
        popup.visible = true
    end

    -- Playback state / polling -------------------------------------------

    local last_art_url = nil

    local function set_art(art_url)
        if art_url == last_art_url then
            return
        end
        last_art_url = art_url

        if art_url == "" then
            popup_art.image = nil
        elseif art_url:match("^file://") then
            popup_art.image = art_url:gsub("^file://", "")
        elseif art_url:match("^https?://") then
            -- imagebox can't fetch URLs itself -- download once to a fixed
            -- cache path; never errors if curl is missing/fetch fails, the
            -- old (or no) art just stays.
            awful.spawn.easy_async({ "curl", "-s", "-o", ART_CACHE_PATH, art_url }, function(_, _, _, exit_code)
                if exit_code == 0 then
                    pcall(function() popup_art.image = ART_CACHE_PATH end)
                end
            end)
        end
    end

    -- Nothing playing: hide the icon and title entirely (not just blank
    -- text) -- the pill's own bg (beautiful.music_bg) is all that's left,
    -- no fixed-width placeholder to hold space for.
    local function set_idle()
        icon_widget.visible = false
        title_fixed.visible = false
        title_textbox.text = IDLE_TEXT
        popup_title.text = IDLE_TEXT
        popup_artist.text = ""
        popup_album.text = ""
        playpause_icon.text = icons.music_play
        set_art("")
    end

    local function set_playing(status, artist, title, album, art_url)
        icon_widget.visible = true
        title_fixed.visible = true
        title_textbox.text = (artist ~= "" and (artist .. " - " .. title)) or title
        popup_title.text = title
        popup_artist.text = artist ~= "" and artist or "—"
        popup_album.text = album ~= "" and album or "—"
        playpause_icon.text = (status == "Playing") and icons.music_pause or icons.music_play
        set_art(art_url)
    end

    local function update()
        if not has_playerctl then
            return
        end
        awful.spawn.easy_async({ "playerctl", PLAYER_ARG, "metadata", "--format", METADATA_FORMAT },
            function(stdout, _, _, exit_code)
                local ok = pcall(function()
                    if exit_code ~= 0 or stdout == "" then
                        set_idle()
                        return
                    end

                    local parts = split_fields(stdout:gsub("\n$", ""), "\x1f")
                    local status = parts[1] or ""
                    local artist = parts[2] or ""
                    local title  = parts[3] or ""
                    local album  = parts[4] or ""
                    local art_url = parts[5] or ""

                    if title == "" then
                        set_idle()
                        return
                    end

                    set_playing(status, artist, title, album, art_url)
                end)
                if not ok then
                    set_idle()
                end
            end)
    end

    local function control(cmd)
        return function()
            awful.spawn({ "playerctl", PLAYER_ARG, cmd })
            update()
        end
    end

    prev_button:buttons({ awful.button({}, 1, control("previous")) })
    playpause_button:buttons({ awful.button({}, 1, control("play-pause")) })
    next_button:buttons({ awful.button({}, 1, control("next")) })

    local content = wibox.widget {
        layout  = wibox.layout.fixed.horizontal,
        spacing = dpi(4),
        icon_widget,
        title_fixed,
    }

    content:buttons({
        awful.button({}, 1, toggle_popup),
        awful.button({}, 4, control("next")),
        awful.button({}, 5, control("previous")),
    })

    if has_playerctl then
        gears.timer {
            timeout   = 1.5,
            autostart = true,
            call_now  = true,
            callback  = update,
        }
    else
        set_idle()
    end

    return content
end

return M
