"""Icônes « jeu » de l'interface (paramètres, boutons, messages).

Style Duolingo : formes pleines et arrondies, une ombre plus foncée en bas
et un reflet blanc. Lancer : python3 tool/generate_game_icons.py
"""
import math
import os

from generate_illustrations import ROOT, icon, sparkle

GREEN, GREEN_DARK = '#58CC02', '#58A700'
BLUE, BLUE_DARK, BLUE_LIGHT = '#1CB0F6', '#1899D6', '#84D8FF'
GOLD, GOLD_DARK = '#FFC800', '#E5A800'
ORANGE, ORANGE_DARK = '#FF9600', '#E08600'
RED, RED_DARK = '#FF4B4B', '#EA2B2B'
PURPLE, PURPLE_DARK = '#CE82FF', '#A568CC'
GRAY, GRAY_DARK = '#AFAFAF', '#8F8F8F'
PINK = '#FF86D0'
INK = '#4B4B4B'
WHITE = '#FFFFFF'


def shine(d, width=3):
    return (f'<path d="{d}" fill="none" stroke="{WHITE}" stroke-width="{width}" '
            'stroke-linecap="round" stroke-opacity="0.7"/>')


def plus_badge(x, y, color=GREEN, dark=GREEN_DARK):
    return (f'<circle cx="{x}" cy="{y + 1.5}" r="9" fill="{dark}"/>'
            f'<circle cx="{x}" cy="{y}" r="9" fill="{color}"/>'
            f'<path d="M{x - 4.5} {y} L{x + 4.5} {y} M{x} {y - 4.5} L{x} {y + 4.5}" '
            f'stroke="{WHITE}" stroke-width="3" stroke-linecap="round"/>')


BELL = ('M24 6 C15 6 12 13 12 21 L12 29 L8 35 L40 35 L36 29 L36 21 '
        'C36 13 33 6 24 6 Z')


def bell():
    return (f'<circle cx="24" cy="39" r="5" fill="{ORANGE}"/>'
            f'<path d="{BELL}" fill="{GOLD_DARK}" transform="translate(0 2)"/>'
            f'<path d="{BELL}" fill="{GOLD}"/>'
            f'<rect x="7" y="32" width="34" height="5" rx="2.5" fill="{GOLD_DARK}"/>'
            f'<circle cx="24" cy="5" r="3" fill="{GOLD_DARK}"/>'
            + shine('M17 26 L17 20 C17 16 19 13 21 12'))


def alarm(extra=''):
    legs = (f'<path d="M13 42 L16 37 M35 42 L32 37" stroke="{RED_DARK}" '
            'stroke-width="4" stroke-linecap="round"/>')
    bells = (f'<path d="M4 14 A8 8 0 0 1 15 5 Z" fill="{GOLD}"/>'
             f'<path d="M44 14 A8 8 0 0 0 33 5 Z" fill="{GOLD}"/>')
    return (legs + bells
            + f'<circle cx="24" cy="26" r="16" fill="{RED_DARK}"/>'
            f'<circle cx="24" cy="24.5" r="16" fill="{RED}"/>'
            f'<circle cx="24" cy="25" r="11.5" fill="{WHITE}"/>'
            f'<path d="M24 25 L24 17.5 M24 25 L29 28" stroke="{INK}" stroke-width="3" '
            'stroke-linecap="round"/>'
            f'<circle cx="24" cy="25" r="2" fill="{INK}"/>'
            + shine('M12 20 A13 13 0 0 1 17 12.5', 2.5) + extra)


def person(color, dark, x=0, y=0, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M7 44 C7 31 41 31 41 44 Z" fill="{dark}"/>'
            f'<path d="M7 42 C7 30 41 30 41 42 Z" fill="{color}"/>'
            f'<circle cx="24" cy="17" r="11" fill="{dark}"/>'
            f'<circle cx="24" cy="15.5" r="11" fill="{color}"/>'
            f'<circle cx="20" cy="15" r="1.8" fill="{INK}"/>'
            f'<circle cx="28" cy="15" r="1.8" fill="{INK}"/>'
            f'<path d="M20 20 Q24 23.5 28 20" fill="none" stroke="{INK}" '
            'stroke-width="2" stroke-linecap="round"/>'
            + shine('M16 12 A9 9 0 0 1 20 7.5', 2.5) + '</g>')


def gear():
    teeth = []
    for i in range(8):
        a = i * math.pi / 4
        x, y = 24 + 16 * math.cos(a), 24 + 16 * math.sin(a)
        teeth.append(f'<rect x="{x - 4.5:.1f}" y="{y - 4.5:.1f}" width="9" height="9" rx="2.5" '
                     f'transform="rotate({i * 45} {x:.1f} {y:.1f})" fill="{GRAY}"/>')
    return (''.join(teeth)
            + f'<circle cx="24" cy="25.5" r="15" fill="{GRAY_DARK}"/>'
            f'<circle cx="24" cy="24" r="15" fill="{GRAY}"/>'
            f'<circle cx="24" cy="24" r="6" fill="{WHITE}"/>'
            + shine('M13 20 A12 12 0 0 1 19 13', 2.5))


def sun():
    rays = ''.join(
        f'<path d="M{24 + 15 * math.cos(a):.1f} {24 + 15 * math.sin(a):.1f} '
        f'L{24 + 21 * math.cos(a):.1f} {24 + 21 * math.sin(a):.1f}" stroke="{ORANGE}" '
        'stroke-width="4" stroke-linecap="round"/>'
        for a in (i * math.pi / 4 for i in range(8)))
    return (rays
            + f'<circle cx="24" cy="25.5" r="11.5" fill="{ORANGE_DARK}"/>'
            f'<circle cx="24" cy="24" r="11.5" fill="{GOLD}"/>'
            f'<circle cx="20.5" cy="23" r="1.6" fill="{INK}"/>'
            f'<circle cx="27.5" cy="23" r="1.6" fill="{INK}"/>'
            f'<path d="M20.5 27 Q24 30 27.5 27" fill="none" stroke="{INK}" '
            'stroke-width="2" stroke-linecap="round"/>'
            + shine('M16 20 A9 9 0 0 1 20 15.5', 2.5))


ICONS = {
    # Mon compte.
    'profile': icon(person(GREEN, GREEN_DARK)),
    'mail': icon(f'<rect x="4" y="12" width="40" height="28" rx="6" fill="{BLUE_DARK}"/>'
                 f'<rect x="4" y="10" width="40" height="28" rx="6" fill="{BLUE}"/>'
                 f'<path d="M6 14 L24 27 L42 14" fill="none" stroke="{BLUE_LIGHT}" '
                 'stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
                 f'<path d="M38 5 C40 1 46 3 44 8 L38 13 L32 8 C30 3 36 1 38 5 Z" '
                 f'fill="{RED}"/>'),
    'pencil': icon('<g transform="rotate(45 24 24)">'
                   f'<rect x="18" y="2" width="12" height="8" rx="3" fill="{PINK}"/>'
                   f'<rect x="18" y="9" width="12" height="4" fill="{GRAY}"/>'
                   f'<rect x="18" y="13" width="12" height="22" fill="{GOLD}"/>'
                   f'<rect x="25" y="13" width="5" height="22" fill="{GOLD_DARK}"/>'
                   '<path d="M18 35 L30 35 L24 46 Z" fill="#F5D6A6"/>'
                   f'<path d="M22.2 42.5 L25.8 42.5 L24 46 Z" fill="{INK}"/>'
                   '</g>'),
    'logout': icon(f'<rect x="6" y="5" width="24" height="38" rx="4" fill="{ORANGE_DARK}"/>'
                   f'<rect x="6" y="4" width="22" height="38" rx="4" fill="{ORANGE}"/>'
                   f'<circle cx="23" cy="24" r="2.2" fill="{GOLD}"/>'
                   f'<path d="M24 24 L42 24 M35 17 L42 24 L35 31" fill="none" '
                   f'stroke="{BLUE_DARK}" stroke-width="6" stroke-linecap="round" '
                   'stroke-linejoin="round" transform="translate(0 1.5)"/>'
                   f'<path d="M24 24 L42 24 M35 17 L42 24 L35 31" fill="none" '
                   f'stroke="{BLUE}" stroke-width="6" stroke-linecap="round" '
                   'stroke-linejoin="round"/>'),
    'settings': icon(gear()),
    # Alertes.
    'bell': icon(bell()),
    'bell_ring': icon(bell()
                      + f'<path d="M5 13 A16 16 0 0 1 10 5 M43 13 A16 16 0 0 0 38 5" '
                      f'fill="none" stroke="{ORANGE}" stroke-width="3.5" '
                      'stroke-linecap="round"/>'),
    'alarm': icon(alarm()),
    'alarm_add': icon(alarm(plus_badge(38, 38))),
    'sun': icon(sun()),
    # Boutons.
    'share': icon(f'<path d="M4 23 L43 6 L33 42 L22 30 Z" fill="{BLUE_DARK}"/>'
                  f'<path d="M4 22 L43 5 L22 29 Z" fill="{BLUE}"/>'
                  f'<path d="M22 29 L43 5 L33 41 Z" fill="{BLUE_LIGHT}"/>'
                  f'<path d="M22 29 L20 41 L27 34 Z" fill="{BLUE_DARK}"/>'),
    'add_friend': icon(person(BLUE, BLUE_DARK, -2, 2, 0.9) + plus_badge(37, 12)),
    'speaker': icon(f'<path d="M6 18 L14 18 L25 8 L25 40 L14 30 L6 30 Z" '
                    f'fill="{BLUE_DARK}" transform="translate(0 1.5)"/>'
                    f'<path d="M6 18 L14 18 L25 8 L25 40 L14 30 L6 30 Z" fill="{BLUE}"/>'
                    f'<path d="M31 17 A10 10 0 0 1 31 31 M36 11 A18 18 0 0 1 36 37" '
                    f'fill="none" stroke="{BLUE}" stroke-width="4" stroke-linecap="round"/>'),
    'trash': icon(f'<rect x="10" y="13" width="28" height="31" rx="5" fill="{GRAY_DARK}"/>'
                  f'<rect x="10" y="12" width="28" height="30" rx="5" fill="{GRAY}"/>'
                  f'<path d="M18 19 L18 35 M24 19 L24 35 M30 19 L30 35" stroke="{WHITE}" '
                  'stroke-width="3" stroke-linecap="round"/>'
                  f'<rect x="6" y="6" width="36" height="6" rx="3" fill="{GRAY_DARK}"/>'
                  f'<rect x="19" y="2" width="10" height="6" rx="2" fill="{GRAY_DARK}"/>'),
    'glass': icon(f'<path d="M9 5 L39 5 L35 43 L13 43 Z" fill="#E8F7FF" stroke="{BLUE_DARK}" '
                  'stroke-width="3" stroke-linejoin="round"/>'
                  f'<path d="M11.5 19 C18 16 30 22 36.5 19 L34 41 L14 41 Z" fill="{BLUE}"/>'
                  + shine('M15 24 L16.5 36', 2.5)
                  + f'<path d="M36 5 A6 6 0 1 1 45 13" fill="none" stroke="{GREEN}" '
                  'stroke-width="3" stroke-linecap="round"/>'),
    # Messages.
    'check_badge': icon(f'<circle cx="24" cy="25.5" r="19" fill="{GREEN_DARK}"/>'
                        f'<circle cx="24" cy="24" r="19" fill="{GREEN}"/>'
                        f'<path d="M15 24.5 L21.5 31 L33.5 18" fill="none" stroke="{WHITE}" '
                        'stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
                        + shine('M10 19 A15 15 0 0 1 16 11', 2.5)),
    'warning': icon(f'<path d="M24 6 L44 40 L4 40 Z" fill="{RED_DARK}" stroke="{RED_DARK}" '
                    'stroke-width="6" stroke-linejoin="round" transform="translate(0 2)"/>'
                    f'<path d="M24 6 L44 40 L4 40 Z" fill="{RED}" stroke="{RED}" '
                    'stroke-width="6" stroke-linejoin="round"/>'
                    f'<path d="M24 17 L24 28" stroke="{WHITE}" stroke-width="5" '
                    'stroke-linecap="round"/>'
                    f'<circle cx="24" cy="35" r="3" fill="{WHITE}"/>'),
    # Pas de réseau : un nuage triste.
    'offline': icon(f'<path d="M13 38 A9 9 0 0 1 12 20 A12 12 0 0 1 35 17 A10.5 10.5 0 0 1 36 38 Z" '
                    f'fill="{GRAY_DARK}" transform="translate(0 2)"/>'
                    f'<path d="M13 38 A9 9 0 0 1 12 20 A12 12 0 0 1 35 17 A10.5 10.5 0 0 1 36 38 Z" '
                    f'fill="#D8D8D8"/>'
                    f'<circle cx="19" cy="27" r="2" fill="{INK}"/>'
                    f'<circle cx="29" cy="27" r="2" fill="{INK}"/>'
                    f'<path d="M19.5 34 Q24 30.5 28.5 34" fill="none" stroke="{INK}" '
                    'stroke-width="2.2" stroke-linecap="round"/>'
                    + f'<path d="M40 6 L40 13" stroke="{RED}" stroke-width="3.5" '
                    'stroke-linecap="round"/>'
                    f'<circle cx="40" cy="18" r="2" fill="{RED}"/>'),
    'sparkle': icon(sparkle(24, 24, 2, GOLD) + sparkle(40, 9, 0.6, BLUE)),
}


if __name__ == '__main__':
    for name, content in ICONS.items():
        with open(os.path.join(ROOT, 'icons', f'{name}.svg'), 'w') as f:
            f.write(content)
    print('ok', len(ICONS))
