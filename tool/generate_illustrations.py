"""Génère les illustrations SVG de Bois & Vis."""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')

KIDNEY = ('M110 25 C155 25 175 65 172 105 C169 150 140 178 105 175 '
          'C75 172 60 150 70 130 C76 118 88 112 88 100 '
          'C88 88 76 82 70 70 C60 48 78 25 110 25 Z')
KIDNEY_SHINE = 'M120 42 C145 45 158 65 160 88'

PINK = '#E57373'
PINK_DARK = '#C0504D'
PINK_LIGHT = '#F6A5A5'
WATER = '#4FC3F7'
WATER_DARK = '#0288D1'
INK = '#3B2A2A'


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
            f'width="{w}" height="{h}">\n{body}\n</svg>\n')


def kidney(tx, ty, s=1.0, fill=PINK, face='happy', ureter=True):
    parts = []
    if ureter:
        parts.append(f'<path d="M88 104 C74 122 84 150 72 186" fill="none" '
                     f'stroke="{PINK_LIGHT}" stroke-width="9" stroke-linecap="round"/>')
    parts.append(f'<path d="{KIDNEY}" fill="{fill}" stroke="{PINK_DARK}" stroke-width="4"/>')
    parts.append(f'<path d="{KIDNEY_SHINE}" fill="none" stroke="#FFFFFF" '
                 f'stroke-opacity="0.55" stroke-width="7" stroke-linecap="round"/>')
    parts.append(FACES[face])
    return f'<g transform="translate({tx} {ty}) scale({s})">' + ''.join(parts) + '</g>'


FACES = {
    'happy': (
        f'<circle cx="112" cy="92" r="6" fill="{INK}"/>'
        f'<circle cx="142" cy="92" r="6" fill="{INK}"/>'
        f'<circle cx="114" cy="90" r="2" fill="#FFFFFF"/>'
        f'<circle cx="144" cy="90" r="2" fill="#FFFFFF"/>'
        f'<circle cx="104" cy="110" r="7" fill="#FF8A80" fill-opacity="0.7"/>'
        f'<circle cx="152" cy="110" r="7" fill="#FF8A80" fill-opacity="0.7"/>'
        f'<path d="M114 112 Q127 127 140 112" fill="none" stroke="{INK}" '
        f'stroke-width="4" stroke-linecap="round"/>'),
    'worried': (
        f'<path d="M104 88 L118 81" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
        f'<path d="M150 88 L136 81" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
        f'<circle cx="112" cy="95" r="5.5" fill="{INK}"/>'
        f'<circle cx="142" cy="95" r="5.5" fill="{INK}"/>'
        f'<path d="M112 122 Q119 114 127 121 Q134 128 142 120" fill="none" '
        f'stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'),
    'tired': (
        f'<path d="M104 94 Q112 100 120 94" fill="none" stroke="{INK}" '
        f'stroke-width="4" stroke-linecap="round"/>'
        f'<path d="M134 94 Q142 100 150 94" fill="none" stroke="{INK}" '
        f'stroke-width="4" stroke-linecap="round"/>'
        f'<ellipse cx="127" cy="120" rx="7" ry="5" fill="{INK}"/>'),
    'joy': (
        f'<path d="M104 94 Q112 84 120 94" fill="none" stroke="{INK}" '
        f'stroke-width="4.5" stroke-linecap="round"/>'
        f'<path d="M134 94 Q142 84 150 94" fill="none" stroke="{INK}" '
        f'stroke-width="4.5" stroke-linecap="round"/>'
        f'<circle cx="102" cy="110" r="7" fill="#FF8A80" fill-opacity="0.7"/>'
        f'<circle cx="154" cy="110" r="7" fill="#FF8A80" fill-opacity="0.7"/>'
        f'<path d="M112 108 Q127 134 142 108 Z" fill="{INK}" stroke="{INK}" '
        f'stroke-width="3" stroke-linejoin="round"/>'
        f'<path d="M119 121 Q127 115 135 121 Q127 128 119 121 Z" fill="#FF7B7B"/>'),
    'none': '',
}


def drop(x, y, s=1.0, fill=WATER):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M0 -14 C6 -5 10 0 10 5 A10 10 0 0 1 -10 5 C-10 0 -6 -5 0 -14 Z" '
            f'fill="{fill}"/>'
            f'<path d="M-4 3 A5 5 0 0 0 -1 9" fill="none" stroke="#FFFFFF" '
            f'stroke-width="2" stroke-linecap="round" stroke-opacity="0.8"/></g>')


def glass(x, y, s=1.0, level=0.7, tilt=0):
    top, bottom = 0, 60
    water_y = bottom - (bottom - top) * level
    # Parois légèrement évasées : 0..44 en haut, 5..39 en bas.
    wl = 5 * (bottom - water_y) / 60
    body = (f'<path d="M{wl} {water_y} L{44 - wl} {water_y} L39 60 L5 60 Z" fill="{WATER}" '
            f'fill-opacity="0.85"/>' if level > 0 else '')
    return (f'<g transform="translate({x} {y}) rotate({tilt} 22 30) scale({s})">'
            f'<path d="M0 0 L44 0 L39 60 L5 60 Z" fill="#E1F5FE" fill-opacity="0.6"/>'
            + body +
            f'<path d="M0 0 L44 0 L39 60 L5 60 Z" fill="none" stroke="{WATER_DARK}" '
            f'stroke-width="3" stroke-linejoin="round"/>'
            f'<path d="M8 8 L11 50" stroke="#FFFFFF" stroke-width="3" '
            f'stroke-linecap="round" stroke-opacity="0.8"/></g>')


def bg(color='#E1F5FE', cx=120, cy=100, r=92):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{color}"/>'


def sparkle(x, y, s=1.0, c='#FFD54F'):
    return (f'<path transform="translate({x} {y}) scale({s})" '
            f'd="M0 -10 Q2 -2 10 0 Q2 2 0 10 Q-2 2 -10 0 Q-2 -2 0 -10 Z" fill="{c}"/>')


ILLUSTRATIONS = {}

# Rein en forme qui tient un verre d'eau.
ILLUSTRATIONS['kidney_happy'] = svg(240, 200, ''.join([
    bg(),
    kidney(-10, 0, 1.0),
    '<path d="M168 112 Q182 122 176 138" fill="none" stroke="#C0504D" '
    'stroke-width="6" stroke-linecap="round"/>',
    glass(164, 110, 0.9, 0.75, 8),
    drop(52, 50, 0.9), drop(200, 58, 0.7), drop(40, 150, 0.6),
    sparkle(190, 30, 0.9), sparkle(30, 100, 0.6),
]))

# Calculs rénaux : petites pierres dans le rein, l'eau les dissout.
stones = ''.join(
    f'<path transform="translate({x} {y}) scale({s})" '
    'd="M-9 -2 L-4 -9 L6 -8 L10 0 L5 8 L-6 7 Z" fill="#9E9E9E" stroke="#616161" stroke-width="2"/>'
    for x, y, s in [(118, 150, 1.0), (140, 142, 0.8), (104, 138, 0.7)])
ILLUSTRATIONS['kidney_stones'] = svg(240, 200, ''.join([
    bg('#FFF3E0'),
    kidney(-10, 0, 1.0, face='worried'),
    f'<g transform="translate(-10 0)">{stones}</g>',
    '<path d="M186 58 L200 66 L190 74 L206 82" fill="none" stroke="#E53935" '
    'stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
    '<path d="M180 150 L196 146 L188 160 L204 158" fill="none" stroke="#E53935" '
    'stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
    drop(40, 60, 1.0), drop(28, 96, 0.7), drop(46, 130, 0.8),
]))


def bacterium(x, y, s=1.0):
    spikes = ''.join(
        f'<path d="M0 0 L{dx} {dy}" stroke="#558B2F" stroke-width="3" stroke-linecap="round"/>'
        for dx, dy in [(0, -16), (14, -8), (14, 8), (0, 16), (-14, 8), (-14, -8)])
    return (f'<g transform="translate({x} {y}) scale({s})">{spikes}'
            '<circle r="11" fill="#9CCC65" stroke="#558B2F" stroke-width="3"/>'
            '<circle cx="-4" cy="-2" r="2.5" fill="#33691E"/>'
            '<circle cx="4" cy="-2" r="2.5" fill="#33691E"/>'
            '<path d="M-4 5 Q0 2 4 5" fill="none" stroke="#33691E" stroke-width="2"/></g>')


# Infection urinaire : la vessie, des bactéries que l'eau emporte.
ILLUSTRATIONS['bladder_infection'] = svg(240, 200, ''.join([
    bg('#F1F8E9'),
    '<path d="M62 60 C58 30 182 30 178 60 C176 110 150 140 128 146 L128 172 '
    'L112 172 L112 146 C90 140 64 110 62 60 Z" fill="#F8BBD0" stroke="#C0504D" stroke-width="4"/>',
    '<path d="M64 88 Q92 76 120 88 T176 88 C170 118 148 138 128 144 L112 144 '
    'C92 138 70 118 64 88 Z" fill="' + WATER + '" fill-opacity="0.75"/>',
    '<path d="M62 52 C50 40 40 30 30 26" fill="none" stroke="#F6A5A5" stroke-width="8" stroke-linecap="round"/>',
    '<path d="M178 52 C190 40 200 30 210 26" fill="none" stroke="#F6A5A5" stroke-width="8" stroke-linecap="round"/>',
    bacterium(96, 62, 0.9), bacterium(146, 66, 0.8),
    bacterium(106, 112, 0.8), bacterium(142, 118, 0.7),
    bacterium(120, 186, 0.7),
    '<path d="M86 168 Q96 180 106 192" fill="none" stroke="' + WATER_DARK +
    '" stroke-width="4" stroke-linecap="round"/>',
    '<path d="M154 168 Q144 180 134 192" fill="none" stroke="' + WATER_DARK +
    '" stroke-width="4" stroke-linecap="round"/>',
    drop(34, 120, 0.8), drop(206, 120, 0.8),
]))

# Les reins filtrent : sang chargé à gauche, sang propre à droite, urine en bas.
ILLUSTRATIONS['kidney_filter'] = svg(240, 200, ''.join([
    bg('#FCE4EC'),
    '<path d="M14 80 L52 80" stroke="#C62828" stroke-width="10" stroke-linecap="round"/>',
    '<path d="M48 68 L64 80 L48 92 Z" fill="#C62828"/>',
    ''.join(f'<circle cx="{x}" cy="{y}" r="3.5" fill="#6D4C41"/>'
            for x, y in [(22, 70), (34, 92), (44, 68)]),
    kidney(0, 0, 0.9, face='happy', ureter=False),
    '<path d="M168 80 L214 80" stroke="#E53935" stroke-width="10" stroke-linecap="round"/>',
    '<path d="M210 68 L226 80 L210 92 Z" fill="#E53935"/>',
    '<path d="M80 96 C66 116 78 144 70 168" fill="none" stroke="#F6A5A5" '
    'stroke-width="9" stroke-linecap="round"/>',
    drop(70, 186, 0.9, '#FFE082'),
    ''.join(f'<circle cx="{x}" cy="{y}" r="3" fill="#6D4C41"/>'
            for x, y in [(52, 178), (90, 184)]),
    sparkle(196, 50, 0.8), sparkle(214, 112, 0.6),
    drop(150, 176, 0.8), drop(176, 166, 0.6),
]))

# Déshydratation : rein fatigué qui transpire, verre vide renversé.
ILLUSTRATIONS['kidney_tired'] = svg(240, 200, ''.join([
    bg('#FFF8E1'),
    '<circle cx="204" cy="38" r="18" fill="#FFB300"/>',
    ''.join(f'<path d="M{204 + 26 * c} {38 + 26 * s} L{204 + 34 * c} {38 + 34 * s}" '
            'stroke="#FFB300" stroke-width="4" stroke-linecap="round"/>'
            for c, s in [(1, 0), (-1, 0), (0, 1), (0.7, 0.7), (-0.7, 0.7), (-0.7, -0.7)]),
    kidney(-18, 8, 1.0, fill='#E8A0A0', face='tired'),
    drop(58, 70, 0.6, '#81D4FA'), drop(166, 78, 0.5, '#81D4FA'),
    glass(166, 136, 0.8, 0.0, 100),
    '<path d="M30 186 L90 186 M110 186 L210 186" stroke="#BCAAA4" stroke-width="4" '
    'stroke-linecap="round"/>',
]))

# Forte chaleur : soleil, thermomètre, bouteille d'eau.
ILLUSTRATIONS['sun_heat'] = svg(240, 200, ''.join([
    bg('#FFF3E0'),
    '<circle cx="84" cy="80" r="36" fill="#FFC107"/>',
    ''.join(f'<path d="M{84 + 46 * c:.1f} {80 + 46 * s:.1f} L{84 + 60 * c:.1f} {80 + 60 * s:.1f}" '
            'stroke="#FFA000" stroke-width="6" stroke-linecap="round"/>'
            for c, s in [(1, 0), (-1, 0), (0, 1), (0, -1),
                         (0.707, 0.707), (-0.707, 0.707), (0.707, -0.707), (-0.707, -0.707)]),
    '<circle cx="72" cy="74" r="4" fill="#5D4037"/><circle cx="96" cy="74" r="4" fill="#5D4037"/>',
    '<path d="M72 92 Q84 100 96 92" fill="none" stroke="#5D4037" stroke-width="4" stroke-linecap="round"/>',
    '<rect x="150" y="40" width="20" height="96" rx="10" fill="#FFFFFF" stroke="#8D6E63" stroke-width="3"/>',
    '<rect x="156" y="62" width="8" height="76" rx="4" fill="#E53935"/>',
    '<circle cx="160" cy="146" r="16" fill="#E53935" stroke="#8D6E63" stroke-width="3"/>',
    '<rect x="186" y="96" width="30" height="72" rx="8" fill="' + WATER + '" fill-opacity="0.8" '
    'stroke="' + WATER_DARK + '" stroke-width="3"/>',
    '<rect x="193" y="84" width="16" height="14" rx="3" fill="' + WATER_DARK + '"/>',
    '<path d="M192 120 L210 120" stroke="#FFFFFF" stroke-width="3" stroke-opacity="0.8"/>',
    drop(52, 150, 0.8), drop(84, 164, 0.6), drop(116, 148, 0.7),
]))

# Couleur de l'urine : de clair (bien hydraté) à foncé (il faut boire).
colors = ['#FFFDE7', '#FFF59D', '#FFE082', '#FFB74D', '#E0892F']
bars = ''.join(
    f'<rect x="{36 + i * 36}" y="70" width="26" height="90" rx="13" fill="{c}" '
    'stroke="#A1887F" stroke-width="3"/>' for i, c in enumerate(colors))
ILLUSTRATIONS['urine_colors'] = svg(240, 200, ''.join([
    bg('#F3E5F5'),
    bars,
    '<circle cx="67" cy="44" r="16" fill="#43A047"/>',
    '<path d="M59 44 L65 50 L76 38" fill="none" stroke="#FFFFFF" stroke-width="4" '
    'stroke-linecap="round" stroke-linejoin="round"/>',
    '<path d="M175 28 L193 58 L157 58 Z" fill="#FB8C00" stroke-linejoin="round" '
    'stroke="#FB8C00" stroke-width="4"/>',
    '<path d="M175 38 L175 48" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>',
    '<circle cx="175" cy="53" r="2.2" fill="#FFFFFF"/>',
    '<path d="M36 176 L190 176" stroke="' + WATER_DARK + '" stroke-width="4" stroke-linecap="round"/>',
    '<path d="M184 168 L196 176 L184 184 Z" fill="' + WATER_DARK + '"/>',
]))

# Tension et diabète : cœur avec cadran et morceaux de sucre.
ILLUSTRATIONS['blood_pressure'] = svg(240, 200, ''.join([
    bg('#E8EAF6'),
    '<path d="M110 170 C40 120 40 60 80 52 C98 48 108 60 110 70 C112 60 122 48 140 52 '
    'C180 60 180 120 110 170 Z" fill="#EF5350" stroke="#B71C1C" stroke-width="4"/>',
    '<circle cx="110" cy="100" r="30" fill="#FFFFFF" stroke="#B71C1C" stroke-width="3"/>',
    '<path d="M86 108 A26 26 0 0 1 134 108" fill="none" stroke="#FFCDD2" stroke-width="6"/>',
    '<path d="M122 90 A26 26 0 0 1 134 108" fill="none" stroke="#E53935" stroke-width="6"/>',
    '<path d="M110 108 L128 88" stroke="#37474F" stroke-width="4" stroke-linecap="round"/>',
    '<circle cx="110" cy="108" r="5" fill="#37474F"/>',
    '<rect x="176" y="118" width="26" height="26" rx="4" fill="#FFFFFF" stroke="#90A4AE" stroke-width="3"/>',
    '<rect x="190" y="146" width="26" height="26" rx="4" fill="#FFFFFF" stroke="#90A4AE" stroke-width="3"/>',
    '<rect x="162" y="146" width="26" height="26" rx="4" fill="#FFFFFF" stroke="#90A4AE" stroke-width="3"/>',
    kidney(150, 12, 0.42, face='happy', ureter=False),
]))


def pill(x, y, rot, c1, c2):
    return (f'<g transform="translate({x} {y}) rotate({rot})">'
            f'<path d="M-24 -11 L0 -11 L0 11 L-24 11 A11 11 0 0 1 -24 -11 Z" fill="{c1}"/>'
            f'<path d="M0 -11 L24 -11 A11 11 0 0 1 24 11 L0 11 Z" fill="{c2}"/>'
            '<rect x="-35" y="-11" width="70" height="22" rx="11" fill="none" '
            'stroke="#546E7A" stroke-width="3"/></g>')


# Automédication : comprimés et panneau attention près du rein.
ILLUSTRATIONS['pills_warning'] = svg(240, 200, ''.join([
    bg('#ECEFF1'),
    kidney(58, 20, 0.85, face='worried'),
    pill(56, 60, -30, '#FFFFFF', '#42A5F5'),
    pill(60, 150, 20, '#FFFFFF', '#EF5350'),
    '<path d="M196 110 L226 164 L166 164 Z" fill="#FDD835" stroke="#F9A825" '
    'stroke-width="5" stroke-linejoin="round"/>',
    '<path d="M196 128 L196 146" stroke="#3E2723" stroke-width="6" stroke-linecap="round"/>',
    '<circle cx="196" cy="155" r="3.5" fill="#3E2723"/>',
]))

DRINKS = {}

# Sachet de « pure water » 0,5 L.
DRINKS['pure_water'] = svg(100, 100, ''.join([
    '<path d="M22 22 L78 22 C84 40 84 70 78 84 L22 84 C16 70 16 40 22 22 Z" '
    'fill="' + WATER + '" fill-opacity="0.55" stroke="' + WATER_DARK + '" stroke-width="3" '
    'stroke-linejoin="round"/>',
    '<path d="M22 22 L28 14 L34 22 L40 14 L46 22 L52 14 L58 22 L64 14 L70 22 L76 14 L78 22" '
    'fill="none" stroke="' + WATER_DARK + '" stroke-width="3" stroke-linejoin="round"/>',
    '<path d="M22 84 L28 92 L34 84 L40 92 L46 84 L52 92 L58 84 L64 92 L70 84 L76 92 L78 84" '
    'fill="none" stroke="' + WATER_DARK + '" stroke-width="3" stroke-linejoin="round"/>',
    '<rect x="30" y="42" width="40" height="22" rx="4" fill="#FFFFFF" fill-opacity="0.9"/>',
    drop(50, 55, 0.75, WATER_DARK),
    '<path d="M28 32 Q26 50 28 72" fill="none" stroke="#FFFFFF" stroke-width="3" '
    'stroke-linecap="round" stroke-opacity="0.8"/>',
]))

DRINKS['glass'] = svg(100, 100, glass(23, 16, 1.2, 0.7))

DRINKS['bottle'] = svg(100, 100, ''.join([
    '<rect x="40" y="8" width="20" height="12" rx="3" fill="' + WATER_DARK + '"/>',
    '<path d="M42 20 L58 20 L58 28 C70 34 72 40 72 48 L72 88 C72 92 69 94 66 94 L34 94 '
    'C31 94 28 92 28 88 L28 48 C28 40 30 34 42 28 Z" fill="' + WATER + '" fill-opacity="0.7" '
    'stroke="' + WATER_DARK + '" stroke-width="3" stroke-linejoin="round"/>',
    '<rect x="28" y="54" width="44" height="18" fill="#FFFFFF" fill-opacity="0.85"/>',
    '<path d="M36 40 L36 86" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-opacity="0.8"/>',
]))

# Icône de l'appli (1024×1024, sans transparence pour iOS).
ICON = svg(1024, 1024, ''.join([
    '<rect width="1024" height="1024" fill="#0288D1"/>',
    '<circle cx="512" cy="512" r="400" fill="#4FC3F7"/>',
    '<g transform="translate(530 540) scale(4.3) translate(-118 -100)">',
    f'<path d="{KIDNEY}" fill="{PINK}" stroke="{PINK_DARK}" stroke-width="4"/>',
    f'<path d="{KIDNEY_SHINE}" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" '
    'stroke-width="7" stroke-linecap="round"/>',
    FACES['happy'],
    '</g>',
    drop(250, 260, 6.0, '#FFFFFF'),
]))


# ---------------------------------------------------------------------------
# Mascotte « Reno » et icônes du jeu (style Duolingo).

def arm(x1, y1, x2, y2):
    return (f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{PINK_DARK}" stroke-width="8" '
            f'stroke-linecap="round"/><circle cx="{x2}" cy="{y2}" r="7" fill="{PINK}" '
            f'stroke="{PINK_DARK}" stroke-width="3"/>')


def mascot(face, arms='', extra='', fill=PINK, tx=-18, ty=0):
    return svg(200, 200, f'<g transform="translate({tx} {ty})">{arms}</g>'
               + kidney(tx, ty, 1.0, fill=fill, face=face) + extra)


MASCOTS = {
    'mascot_happy': mascot('happy', arm(168, 118, 186, 142) + arm(74, 72, 58, 50)),
    'mascot_cheer': mascot(
        'joy', arm(166, 84, 190, 50) + arm(74, 68, 52, 34),
        sparkle(178, 22, 1.1) + sparkle(24, 70, 0.8) + sparkle(186, 150, 0.7, '#4FC3F7')),
    'mascot_sad': mascot(
        'worried', arm(168, 126, 184, 160) + arm(72, 136, 60, 168),
        drop(162, 52, 0.7, '#81D4FA'), fill='#E8A0A0'),
    'mascot_drink': mascot(
        'happy', '<path d="M168 112 Q184 124 178 140" fill="none" stroke="' + PINK_DARK +
        '" stroke-width="8" stroke-linecap="round"/>',
        glass(148, 116, 0.95, 0.75, 8)),
}


def icon(body, size=48):
    return svg(size, size, body)


FLAME = ('M24 4 C27 12 36 16 36 28 A12 12 0 0 1 12 28 C12 22 15 18 18 15 '
         'C18 20 20 23 23 24 C21 16 22 10 24 4 Z')
FLAME_IN = 'M24 22 C26 26 30 28 30 33 A6 6 0 0 1 18 33 C18 29 21 27 24 22 Z'
GEM = 'M24 4 C31 13 38 21 38 29 A14 14 0 0 1 10 29 C10 21 17 13 24 4 Z'

ICONS = {
    'flame': icon(f'<path d="{FLAME}" fill="#FF9600"/><path d="{FLAME_IN}" fill="#FFC800"/>'),
    'flame_off': icon(f'<path d="{FLAME}" fill="#E5E5E5"/><path d="{FLAME_IN}" fill="#F7F7F7"/>'),
    'xp': icon(f'<path d="{GEM}" fill="#1CB0F6"/>'
               '<path d="M24 12 C28 18 32 23 32 29 A8 8 0 0 1 24 37 Z" fill="#1899D6"/>'
               '<path d="M16 28 A8 8 0 0 0 20 35" fill="none" stroke="#FFFFFF" stroke-width="3" '
               'stroke-linecap="round"/>'),
    'crown': icon('<path d="M6 36 L8 14 L17 23 L24 8 L31 23 L40 14 L42 36 Z" fill="#FFC800" '
                  'stroke="#E5A800" stroke-width="3" stroke-linejoin="round"/>'
                  '<rect x="6" y="36" width="36" height="6" rx="2" fill="#E5A800"/>'
                  '<circle cx="24" cy="28" r="3.5" fill="#FF4B4B"/>'),
    'lock': icon('<path d="M15 22 L15 16 A9 9 0 0 1 33 16 L33 22" fill="none" stroke="#AFAFAF" '
                 'stroke-width="5"/><rect x="10" y="21" width="28" height="22" rx="6" fill="#AFAFAF"/>'
                 '<circle cx="24" cy="31" r="3.5" fill="#FFFFFF"/>'),
    'star': icon('<path d="M24 5 L29.5 17.5 L43 18.5 L32.5 27.5 L36 41 L24 33.5 L12 41 L15.5 27.5 '
                 'L5 18.5 L18.5 17.5 Z" fill="#FFC800" stroke="#E5A800" stroke-width="3" '
                 'stroke-linejoin="round"/>'),
    'sunrise': icon('<path d="M8 34 A16 16 0 0 1 40 34 Z" fill="#FF9600"/>'
                    + ''.join(f'<path d="M{24 + 16 * c:.1f} {30 - 16 * s:.1f} L{24 + 21 * c:.1f} '
                              f'{30 - 21 * s:.1f}" stroke="#FFC800" stroke-width="3.5" '
                              'stroke-linecap="round"/>'
                              for c, s in [(1, 0.1), (0.7, 0.7), (0, 1), (-0.7, 0.7), (-1, 0.1)])
                    + '<rect x="4" y="34" width="40" height="5" rx="2.5" fill="#1CB0F6"/>'),
    'moon': icon('<path d="M30 6 A18 18 0 1 0 42 32 A14 14 0 1 1 30 6 Z" fill="#8E7CF0"/>'
                 + sparkle(12, 12, 0.5, '#FFC800') + sparkle(38, 12, 0.35, '#FFC800')),
    'book': icon('<path d="M4 10 C12 8 19 9 24 13 L24 42 C19 38 12 37 4 39 Z" fill="#1CB0F6"/>'
                 '<path d="M44 10 C36 8 29 9 24 13 L24 42 C29 38 36 37 44 39 Z" fill="#1899D6"/>'
                 '<path d="M9 17 L19 18 M9 23 L19 24 M29 18 L39 17 M29 24 L39 23" stroke="#FFFFFF" '
                 'stroke-width="2.5" stroke-linecap="round"/>'),
    'trophy': icon('<path d="M13 6 L35 6 L35 18 A11 11 0 0 1 13 18 Z" fill="#FFC800"/>'
                   '<path d="M13 10 L6 10 A7 7 0 0 0 14 20 M35 10 L42 10 A7 7 0 0 1 34 20" fill="none" '
                   'stroke="#FFC800" stroke-width="4"/>'
                   '<rect x="21" y="28" width="6" height="8" fill="#E5A800"/>'
                   '<rect x="14" y="36" width="20" height="7" rx="3" fill="#E5A800"/>'),
    'home': icon('<path d="M6 22 L24 7 L42 22" fill="none" stroke="#FF9600" stroke-width="5" '
                 'stroke-linecap="round" stroke-linejoin="round"/>'
                 '<path d="M11 20 L11 41 L37 41 L37 20 L24 10 Z" fill="#FFC800"/>'
                 '<rect x="19" y="27" width="10" height="14" rx="3" fill="#FF9600"/>'),
    'drop': icon(drop(24, 25, 1.4, '#1CB0F6')),
    # Glaçon : jour de repos qui protège la flamme.
    'freeze': icon('<rect x="7" y="9" width="34" height="32" rx="8" fill="#84D8FF" '
                   'stroke="#1CB0F6" stroke-width="3"/>'
                   '<path d="M14 17 L22 17 M14 23 L19 23" stroke="#FFFFFF" '
                   'stroke-width="3" stroke-linecap="round"/>'
                   '<path d="M24 4 L24 12 M20 6 L28 10 M28 6 L20 10" stroke="#1CB0F6" '
                   'stroke-width="2.5" stroke-linecap="round"/>'),
}

KIDNEY_ICON = svg(200, 200, kidney(-18, 0, 1.0, face='happy', ureter=False))
ICONS['kidney'] = KIDNEY_ICON


if __name__ == '__main__':
    os.makedirs(f'{ROOT}/illustrations', exist_ok=True)
    os.makedirs(f'{ROOT}/drinks', exist_ok=True)
    os.makedirs(f'{ROOT}/icon', exist_ok=True)
    for name, content in ILLUSTRATIONS.items():
        open(f'{ROOT}/illustrations/{name}.svg', 'w').write(content)
    for name, content in DRINKS.items():
        open(f'{ROOT}/drinks/{name}.svg', 'w').write(content)
    open(f'{ROOT}/icon/app_icon.svg', 'w').write(ICON)
    os.makedirs(f'{ROOT}/mascot', exist_ok=True)
    os.makedirs(f'{ROOT}/icons', exist_ok=True)
    for name, content in MASCOTS.items():
        open(f'{ROOT}/mascot/{name}.svg', 'w').write(content)
    for name, content in ICONS.items():
        open(f'{ROOT}/icons/{name}.svg', 'w').write(content)
    print('ok', len(ILLUSTRATIONS), len(DRINKS))


# ---------------------------------------------------------------------------
# Images des notifications (PNG : Android et iOS n'affichent pas le SVG).

def _inner(svg_text):
    return svg_text[svg_text.index('>') + 1:svg_text.rindex('</svg>')]


def banner(svg_text, w0, h0, bg='#DDF4FF'):
    """Illustration centrée sur un bandeau 1024×512 (grande image)."""
    scale = min(900 / w0, 460 / h0)
    x = (1024 - w0 * scale) / 2
    y = (512 - h0 * scale) / 2
    return svg(1024, 512, f'<rect width="1024" height="512" fill="{bg}"/>'
               + drop(90, 90, 2.2, '#FFFFFF') + drop(940, 420, 1.6, '#FFFFFF')
               + f'<g transform="translate({x:.1f} {y:.1f}) scale({scale:.3f})">'
               + _inner(svg_text) + '</g>')


def write_notification_images():
    try:
        import cairosvg
    except ImportError:
        print('cairosvg absent : images des notifications non générées')
        return
    out = f'{ROOT}/notif'
    os.makedirs(out, exist_ok=True)
    for name, content in ILLUSTRATIONS.items():
        cairosvg.svg2png(bytestring=banner(content, 240, 200).encode(),
                         write_to=f'{out}/{name}.png', output_width=1024)
    for name in ('mascot_drink', 'mascot_cheer', 'mascot_sad'):
        cairosvg.svg2png(bytestring=banner(MASCOTS[name], 200, 200).encode(),
                         write_to=f'{out}/{name}.png', output_width=1024)
    # Petite icône ronde à droite de la notification.
    face = svg(256, 256, '<circle cx="128" cy="128" r="128" fill="#1CB0F6"/>'
               '<g transform="translate(128 140) scale(1.05) translate(-118 -100)">'
               + _inner(KIDNEY_ICON) + '</g>')
    cairosvg.svg2png(bytestring=face.encode(), write_to=f'{out}/reno_face.png',
                     output_width=256)
    print('images des notifications :', len(os.listdir(out)))


if __name__ == '__main__':
    write_notification_images()
