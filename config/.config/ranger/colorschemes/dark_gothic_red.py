# This file is part of ranger, the console file manager.
# License: GNU GPL version 3, see the file "AUTHORS" for details.
#
# Dark Gothic Red colorscheme — matches the setup-wide palette documented
# in dotfiles/THEME.md (AwesomeWM + picom + Alacritty).
#
# Monochrome design: file-type identity is carried by devicons glyphs, so
# color is purely hierarchical — red family for structure, near-white for
# content, pastel as the single secondary accent, bright red reserved for
# urgent states (errors, marks, broken links).
#
# Colors come primarily from ANSI 0-15, which Alacritty maps to the exact
# theme hexes. Two xterm-256 codes cover the intermediate dark reds that
# have no ANSI slot.

from __future__ import absolute_import, division, print_function

from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import (
    default,
    normal,
    bold,
    reverse,
    default_colors,
)

# ANSI slots (exact theme hexes via Alacritty)
NEAR_BLACK = 0    # c5 #20080a — near-black red
RED = 1           # c_2 #b70803 — medium red, main structural color
PASTEL = 5        # t #cf91b5 — pastel accent, secondary text
EMBER = 8         # c3 #3f0f10 — deep dark red, faded/whisper states
RED_BRIGHT = 9    # c_1 #e81509 — bright red, urgent/highlight ONLY
TEXT = 15         # l #f2eaea — near-white text

# xterm-256 approximations (no ANSI slot for these theme reds)
RED_DARK = 88     # c1 #7a1f20 -> #870000, quiet informational states
RED_DEEPER = 52   # c2 #5c1717 -> #5f0000, inactive elements


class DarkGothicRed(ColorScheme):
    progress_bar_color = RED_DARK

    def verify_browser(self, context, fg, bg, attr):
        if context.selected:
            attr = reverse
        else:
            attr = normal
        if context.empty or context.error:
            bg = RED
            fg = TEXT
        if context.border:
            fg = default
        if context.media or context.document or context.container:
            # File types are identified by devicons glyphs, not color
            fg = default
        if context.directory:
            attr |= bold
            fg = RED
        elif context.executable and not any(
            (context.media, context.container, context.fifo, context.socket)
        ):
            attr |= bold
            fg = TEXT
        if context.socket or context.fifo or context.device:
            attr |= bold
            fg = RED_DARK
        if context.link:
            fg = PASTEL if context.good else RED_BRIGHT
        if context.tag_marker and not context.selected:
            attr |= bold
            fg = RED_BRIGHT
        if not context.selected and (context.cut or context.copied):
            fg = EMBER
            attr |= bold
        if context.main_column:
            if context.selected:
                attr |= bold
            if context.marked:
                attr |= bold
                fg = RED_BRIGHT
        if context.badinfo:
            if attr & reverse:
                bg = RED_BRIGHT
            else:
                fg = RED_BRIGHT

        if context.inactive_pane:
            fg = RED_DEEPER

        return fg, bg, attr

    def verify_titlebar(self, context, fg, bg, attr):
        attr |= bold
        if context.hostname:
            fg = RED_BRIGHT if context.bad else PASTEL
        elif context.directory:
            fg = RED
        elif context.tab:
            if context.good:
                bg = RED_DARK
        elif context.link:
            fg = PASTEL

        return fg, bg, attr

    def verify_statusbar(self, context, fg, bg, attr):
        if context.permissions:
            if context.good:
                fg = PASTEL
            elif context.bad:
                bg = RED
                fg = TEXT
        if context.marked:
            attr |= bold | reverse
            fg = RED_BRIGHT
        if context.frozen:
            attr |= bold | reverse
            fg = PASTEL
        if context.message:
            if context.bad:
                attr |= bold
                fg = RED_BRIGHT
        if context.loaded:
            bg = self.progress_bar_color
        if context.vcsinfo:
            fg = PASTEL
            attr &= ~bold
        if context.vcscommit:
            fg = RED_DARK
            attr &= ~bold
        if context.vcsdate:
            fg = RED_DARK
            attr &= ~bold

        return fg, bg, attr

    def verify_taskview(self, context, fg, bg, attr):
        if context.title:
            fg = RED

        if context.selected:
            attr |= reverse

        if context.loaded:
            if context.selected:
                fg = self.progress_bar_color
            else:
                bg = self.progress_bar_color

        return fg, bg, attr

    def verify_vcsfile(self, context, fg, bg, attr):
        attr &= ~bold
        if context.vcsconflict:
            fg = RED_BRIGHT
        elif context.vcschanged:
            fg = RED
        elif context.vcsunknown:
            fg = EMBER
        elif context.vcsstaged:
            fg = RED_DARK
        elif context.vcssync:
            fg = RED_DARK
        elif context.vcsignored:
            fg = default

        return fg, bg, attr

    def verify_vcsremote(self, context, fg, bg, attr):
        attr &= ~bold
        if context.vcssync or context.vcsnone:
            fg = RED_DARK
        elif context.vcsbehind:
            fg = RED
        elif context.vcsahead:
            fg = PASTEL
        elif context.vcsdiverged:
            fg = RED_BRIGHT
        elif context.vcsunknown:
            fg = EMBER

        return fg, bg, attr

    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        elif context.in_browser:
            fg, bg, attr = self.verify_browser(context, fg, bg, attr)

        elif context.in_titlebar:
            fg, bg, attr = self.verify_titlebar(context, fg, bg, attr)

        elif context.in_statusbar:
            fg, bg, attr = self.verify_statusbar(context, fg, bg, attr)

        if context.text:
            if context.highlight:
                attr |= reverse

        if context.in_taskview:
            fg, bg, attr = self.verify_taskview(context, fg, bg, attr)

        if context.vcsfile and not context.selected:
            fg, bg, attr = self.verify_vcsfile(context, fg, bg, attr)

        elif context.vcsremote and not context.selected:
            fg, bg, attr = self.verify_vcsremote(context, fg, bg, attr)

        return fg, bg, attr
