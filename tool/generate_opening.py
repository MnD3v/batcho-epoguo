"""Grande illustration de l'écran d'ouverture : Reno et sa bande (verre,
bouteille, citron, gouttes, soleil) qui font la fête sur une vague.

Lancer : python3 tool/generate_opening.py
"""
import os

from generate_game_icons import sun
from generate_illustrations import INK, MASCOTS, ROOT, glass, sparkle, svg
from generate_lesson_art import lemon_slice

W, H = 400, 440
NAVY = '#0B4F9C'


def inner(svg_text):
    return svg_text[svg_text.index('>') + 1:svg_text.rindex('</svg>')]


def eyes(x, y, gap=10, r=3.2, look=0):
    return (f'<circle cx="{x - gap / 2}" cy="{y}" r="{r + 2.4}" fill="#FFFFFF"/>'
            f'<circle cx="{x + gap / 2}" cy="{y}" r="{r + 2.4}" fill="#FFFFFF"/>'
            f'<circle cx="{x - gap / 2 + look}" cy="{y + 0.5}" r="{r}" fill="{INK}"/>'
            f'<circle cx="{x + gap / 2 + look}" cy="{y + 0.5}" r="{r}" fill="{INK}"/>')


def smile(x, y, w=10, open_=False):
    if open_:
        return (f'<path d="M{x - w / 2} {y} Q{x} {y + w} {x + w / 2} {y} Z" '
                f'fill="{INK}"/><path d="M{x - w / 4} {y + w / 2.6} Q{x} {y + w / 4} '
                f'{x + w / 4} {y + w / 2.6} Q{x} {y + w / 1.8} {x - w / 4} {y + w / 2.6} Z" '
                'fill="#FF7B7B"/>')
    return (f'<path d="M{x - w / 2} {y} Q{x} {y + w * 0.7} {x + w / 2} {y}" fill="none" '
            f'stroke="{INK}" stroke-width="2.6" stroke-linecap="round"/>')


def drop_buddy(x, y, s=1.0, color='#1CB0F6', look=0):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M0 -26 C11 -10 18 -1 18 9 A18 18 0 0 1 -18 9 '
            f'C-18 -1 -11 -10 0 -26 Z" fill="{color}" stroke="#1899D6" stroke-width="2.5"/>'
            '<path d="M-10 4 A10 10 0 0 0 -5 16" fill="none" stroke="#FFFFFF" '
            'stroke-width="3" stroke-linecap="round" stroke-opacity="0.8"/>'
            + eyes(0, 4, 11, 2.6, look) + smile(0, 13, 9, open_=True) + '</g>')


def glass_buddy(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})">' + glass(0, 0, 1.0, 0.7)
            + eyes(22, 30, 12, 2.8) + smile(22, 40, 10) +
            # Bras levés.
            '<path d="M2 26 L-12 8 M42 26 L56 10" stroke="#1899D6" stroke-width="4" '
            'stroke-linecap="round"/></g>')


def bottle_buddy(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<rect x="12" y="-8" width="16" height="12" rx="3" fill="#58CC02"/>'
            '<path d="M8 4 L32 4 L38 18 L38 92 C38 98 34 102 28 102 L12 102 '
            'C6 102 2 98 2 92 L2 18 Z" fill="#DDF4FF" stroke="#1899D6" stroke-width="3"/>'
            '<path d="M2 40 L38 40 L38 92 C38 98 34 102 28 102 L12 102 C6 102 2 98 2 92 Z" '
            'fill="#84D8FF"/>'
            '<rect x="2" y="50" width="36" height="20" fill="#1CB0F6"/>'
            + eyes(20, 28, 12, 2.8, -1) + smile(20, 38, 10, open_=True)
            + '<path d="M9 16 L9 32" stroke="#FFFFFF" stroke-width="3" '
            'stroke-linecap="round"/>'
            '<path d="M-2 60 L-16 44 M42 60 L56 46" stroke="#1899D6" stroke-width="4" '
            'stroke-linecap="round"/></g>')


def lemon_buddy(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})">' + lemon_slice(0, 0, 1.0)
            + eyes(0, -2, 12, 2.6, 1) + smile(0, 7, 9) + '</g>')


def sun_buddy(x, y, s=1.0):
    return f'<g transform="translate({x} {y}) scale({s})">' + sun() + '</g>'


def confetti():
    bits = [(40, 60, '#FFC800', 20), (110, 30, '#FF4B4B', -30), (300, 40, '#58CC02', 45),
            (360, 120, '#CE82FF', 10), (30, 170, '#1CB0F6', 60), (370, 230, '#FF9600', -20),
            (150, 90, '#58CC02', 70), (260, 110, '#FF86D0', -50)]
    return ''.join(f'<rect x="{x}" y="{y}" width="12" height="6" rx="3" fill="{c}" '
                   f'transform="rotate({r} {x + 6} {y + 3})"/>' for x, y, c, r in bits)


def waves():
    return ('<path d="M0 330 C70 300 130 350 200 330 C270 310 330 350 400 325 '
            'L400 440 L0 440 Z" fill="#84D8FF"/>'
            '<path d="M0 365 C80 340 140 385 210 362 C280 340 340 380 400 360 '
            'L400 440 L0 440 Z" fill="#1CB0F6"/>'
            f'<path d="M0 395 C90 375 150 410 220 392 C290 375 350 405 400 392 '
            f'L400 440 L0 440 Z" fill="{NAVY}"/>')


OPENING = svg(W, H, ''.join([
    f'<rect width="{W}" height="{H}" fill="#FFF8E7"/>',
    # Grand halo derrière Reno.
    '<circle cx="200" cy="220" r="150" fill="#DDF4FF"/>',
    '<circle cx="200" cy="220" r="110" fill="#C3EBFF"/>',
    confetti(),
    sun_buddy(318, 22, 1.5),
    lemon_buddy(62, 112, 1.3),
    bottle_buddy(318, 190, 1.05),
    drop_buddy(48, 250, 1.1),
    drop_buddy(362, 300, 0.8, look=-1),
    # Reno, héros de la fête.
    f'<g transform="translate(90 90) scale(1.25)">{inner(MASCOTS["mascot_cheer"])}</g>',
    glass_buddy(96, 262, 1.25),
    drop_buddy(250, 318, 0.9, look=1),
    waves(),
    sparkle(160, 60, 1.2, '#FFC800'), sparkle(250, 50, 0.8, '#1CB0F6'),
]))


if __name__ == '__main__':
    with open(os.path.join(ROOT, 'illustrations', 'opening_party.svg'), 'w') as f:
        f.write(OPENING)
    print('ok')
