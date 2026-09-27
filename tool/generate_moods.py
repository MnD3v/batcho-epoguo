"""Les cinq humeurs de Reno, de « très triste » à « très joyeux ».

Affichées en haut du parcours selon l'heure et l'eau bue, et en avatar rond
dans les notifications (le visage change d'une alerte à l'autre, comme la
chouette de Duolingo).
Lancer : python3 tool/generate_moods.py
"""
import os

from generate_illustrations import (FACES, INK, PINK, ROOT, arm, drop, kidney,
                                    mascot, sparkle, svg)

TEAR = '#4FC3F7'

FACES['crying'] = (
    # Sourcils tombants, yeux fermés, bouche à l'envers, larmes.
    f'<path d="M102 90 L118 83" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
    f'<path d="M152 90 L136 83" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
    f'<path d="M104 98 Q112 92 120 98" fill="none" stroke="{INK}" '
    'stroke-width="4" stroke-linecap="round"/>'
    f'<path d="M134 98 Q142 92 150 98" fill="none" stroke="{INK}" '
    'stroke-width="4" stroke-linecap="round"/>'
    f'<path d="M114 128 Q127 114 140 128" fill="none" stroke="{INK}" '
    'stroke-width="4.5" stroke-linecap="round"/>'
    f'<path d="M108 102 C104 112 106 124 104 134" fill="none" stroke="{TEAR}" '
    'stroke-width="5" stroke-linecap="round"/>'
    f'<path d="M146 102 C150 112 148 124 150 134" fill="none" stroke="{TEAR}" '
    'stroke-width="5" stroke-linecap="round"/>')

FACES['neutral'] = (
    f'<circle cx="112" cy="94" r="6" fill="{INK}"/>'
    f'<circle cx="142" cy="94" r="6" fill="{INK}"/>'
    '<circle cx="114" cy="92" r="2" fill="#FFFFFF"/>'
    '<circle cx="144" cy="92" r="2" fill="#FFFFFF"/>'
    f'<path d="M116 118 L138 118" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>')

MOODS = {
    # 0 · Très triste : rein pâle et desséché qui pleure.
    'mood_0': mascot('crying', arm(168, 130, 180, 166) + arm(72, 140, 62, 172),
                     drop(40, 150, 0.6, TEAR) + drop(186, 176, 0.5, TEAR),
                     fill='#D9A8A8'),
    # 1 · Triste : inquiet, une goutte de sueur.
    'mood_1': mascot('worried', arm(168, 126, 184, 160) + arm(72, 136, 60, 168),
                     drop(162, 52, 0.7, '#81D4FA'), fill='#E8A0A0'),
    # 2 · Bof : il attend son verre.
    'mood_2': mascot('neutral', arm(168, 122, 186, 150) + arm(72, 128, 58, 156)),
    # 3 · Content.
    'mood_3': mascot('happy', arm(168, 118, 186, 142) + arm(74, 72, 58, 50)),
    # 4 · Très joyeux : bras en l'air et étincelles.
    'mood_4': mascot('joy', arm(166, 84, 190, 50) + arm(74, 68, 52, 34),
                     sparkle(178, 22, 1.1) + sparkle(24, 70, 0.8)
                     + sparkle(186, 150, 0.7, TEAR) + sparkle(30, 150, 0.6)),
}

# Avatars des notifications : le visage seul, sur un rond bleu.
AVATARS = {
    'reno_mood_0': ('crying', '#D9A8A8', ''),
    'reno_mood_1': ('worried', '#E8A0A0', drop(208, 70, 1.3, '#FFFFFF')),
    'reno_mood_2': ('neutral', PINK, ''),
    'reno_mood_3': ('happy', PINK, ''),
    'reno_mood_4': ('joy', PINK, sparkle(206, 60, 1.6, '#FFC800')
                    + sparkle(52, 196, 1.1, '#FFC800')),
}


def avatar(face, fill, extra):
    return svg(256, 256, '<circle cx="128" cy="128" r="128" fill="#1CB0F6"/>'
               '<g transform="translate(128 140) scale(1.05) translate(-118 -100)">'
               + kidney(-18, 0, 1.0, fill=fill, face=face, ureter=False)
               + '</g>' + extra)


if __name__ == '__main__':
    import cairosvg
    for name, (face, fill, extra) in AVATARS.items():
        cairosvg.svg2png(bytestring=avatar(face, fill, extra).encode(),
                         write_to=os.path.join(ROOT, 'notif', f'{name}.png'),
                         output_width=256)
    for name, content in MOODS.items():
        with open(os.path.join(ROOT, 'mascot', f'{name}.svg'), 'w') as f:
            f.write(content)
    print('ok', len(MOODS))
