---------------------------------------------
-- Tiling layouts available for cycling/direct-jump (keys/global.lua).
-- qtile equivalents noted for reference during the migration.
---------------------------------------------

local awful = require("awful")

awful.layout.layouts = {
    awful.layout.suit.tile,        -- master left, stack right  (~qtile MonadTall)
    awful.layout.suit.tile.bottom, -- master top,  stack bottom (~qtile MonadWide)
    awful.layout.suit.max,         -- fullscreen focus          (~qtile Max)
    awful.layout.suit.fair,        -- even grid for 3+ clients
}
