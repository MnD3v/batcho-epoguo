"""Illustrations des leçons sur la température de l'eau et l'eau citronnée.

Lancer : python3 tool/generate_lesson_art.py
(SVG dans assets/illustrations, PNG des notifications dans assets/notif.)
"""
import os

from generate_illustrations import (INK, ROOT, WATER, WATER_DARK, banner, bg,
                                    glass, kidney, sparkle, svg)

RED = '#FF6B4A'


def steam(x, y):
    return ''.join(
        f'<path d="M{x + dx} {y} C{x + dx - 8} {y - 12} {x + dx + 8} {y - 22} '
        f'{x + dx} {y - 34}" fill="none" stroke="#B0BEC5" stroke-width="5" '
        'stroke-linecap="round" stroke-opacity="0.8"/>'
        for dx in (0, 18, 36))


def mug(x, y):
    """Tasse d'eau chaude."""
    return (f'<g transform="translate({x} {y})">'
            '<path d="M58 14 C82 14 82 50 56 50" fill="none" stroke="#FF9600" '
            'stroke-width="8"/>'
            '<path d="M0 0 L64 0 L58 66 C57 74 50 78 42 78 L22 78 C14 78 7 74 6 66 Z" '
            'fill="#FFC800" stroke="#E5A800" stroke-width="3"/>'
            '<ellipse cx="32" cy="4" rx="30" ry="5" fill="#FFE8A3"/>'
            f'<path d="M12 26 L14 60" stroke="#FFFFFF" stroke-width="4" '
            'stroke-linecap="round" stroke-opacity="0.7"/></g>')


def thermometer(x, y, level, color):
    return (f'<g transform="translate({x} {y})">'
            '<rect x="0" y="0" width="16" height="70" rx="8" fill="#FFFFFF" '
            'stroke="#90A4AE" stroke-width="3"/>'
            f'<rect x="4" y="{66 - 50 * level:.0f}" width="8" height="{50 * level + 4:.0f}" '
            f'rx="4" fill="{color}"/>'
            f'<circle cx="8" cy="76" r="12" fill="{color}" stroke="#90A4AE" stroke-width="3"/>'
            '</g>')


def ice(x, y, r=0):
    return (f'<g transform="translate({x} {y}) rotate({r})">'
            '<rect x="0" y="0" width="16" height="16" rx="3" fill="#E3F7FF" '
            'stroke="#84D8FF" stroke-width="2.5"/>'
            '<path d="M4 4 L8 4" stroke="#FFFFFF" stroke-width="2.5" '
            'stroke-linecap="round"/></g>')


def lemon_slice(x, y, s=1.0):
    spokes = ''.join(
        f'<path d="M0 0 L{dx} {dy}" stroke="#FFF3B0" stroke-width="2.5"/>'
        for dx, dy in [(0, -15), (13, -7), (13, 7), (0, 15), (-13, 7), (-13, -7)])
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<circle r="20" fill="#FFD60A" stroke="#E5B800" stroke-width="3"/>'
            '<circle r="15" fill="#FFE55C"/>' + spokes + '</g>')


LESSON_ART = {
    'warm_water': svg(240, 200, ''.join([
        bg('#FFF3E0'),
        steam(88, 62),
        mug(78, 70),
        thermometer(172, 64, 0.55, '#FF9600'),
        kidney(-4, 96, 0.42, face='happy', ureter=False),
        sparkle(196, 40, 0.7),
    ])),
    'cold_water': svg(240, 200, ''.join([
        bg('#E3F2FD'),
        glass(84, 64, 1.5, 0.75),
        ice(96, 92, 12), ice(116, 104, -8), ice(104, 118, 20),
        thermometer(178, 62, 0.12, '#1CB0F6'),
        kidney(-4, 96, 0.42, face='worried', ureter=False),
        '<path d="M40 40 L48 48 M48 40 L40 48 M44 36 L44 52 M36 44 L52 44" '
        'stroke="#84D8FF" stroke-width="3" stroke-linecap="round"/>',
    ])),
    'lemon_water': svg(240, 200, ''.join([
        bg('#FFFDE7'),
        glass(84, 64, 1.5, 0.8),
        lemon_slice(150, 72, 1.0),
        lemon_slice(118, 130, 0.55),
        f'<circle cx="104" cy="118" r="3" fill="{WATER_DARK}" fill-opacity="0.4"/>'
        f'<circle cx="126" cy="104" r="2.5" fill="{WATER_DARK}" fill-opacity="0.4"/>',
        kidney(-4, 96, 0.42, face='joy', ureter=False),
        sparkle(190, 130, 0.7),
    ])),
}


if __name__ == '__main__':
    import cairosvg
    for name, content in LESSON_ART.items():
        with open(os.path.join(ROOT, 'illustrations', f'{name}.svg'), 'w') as f:
            f.write(content)
        cairosvg.svg2png(bytestring=banner(content, 240, 200).encode(),
                         write_to=os.path.join(ROOT, 'notif', f'{name}.png'),
                         output_width=1024)
    print('ok', len(LESSON_ART))
