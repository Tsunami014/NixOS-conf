#!/usr/bin/env python3
"""theme-gen: derive a colour scheme from ~/Pictures/currentBg.jpg and write config for each palette.

Lightness and chroma of every role are FIXED, the wallpaper only supplies the hue so colours can't come out pale or murky.
Each palette then restyles groups of roles: how much chroma they get, how far their hue is
turned away from the wallpaper's, how much tonal contrast they have, and how light they are.

Palettes come from palettes.toml next to this script if it exists, otherwise palettes.default.toml.
Templates are read from ../extra, output goes to ~/.local/state/theme/v<N>/.
"""
import json
import math
import os
import sys
import tomllib
from typing import NamedTuple

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
STATE_DIR = os.path.expanduser("~/.local/state/theme")
EXTRA_DIR = os.path.join(HERE, "..", "extra")
TEMPLATES = ("alacritty.toml", "niri.kdl")
WALLPAPER = os.path.expanduser("~/Pictures/currentBg.jpg")
PERSONAL_PALETTES = os.path.join(EXTRA_DIR, "palettes.toml")
DEFAULT_PALETTES = os.path.join(EXTRA_DIR, "palettes.default.toml")

# ---------------------------------------------------------------- tuning knobs
FALLBACK_HUE = 275.0      # used for grey wallpapers
MAX_NUDGE = 9.0           # max degrees a role hue (red, green...) may rotate toward the wallpaper
NUDGE_PULL = 0.30         # fraction of the gap to the wallpaper hue a role closes. Keep well under 0.5,
                          # otherwise neighbouring roles (orange/yellow, cyan/blue) get dragged together
BG_CHROMA = 1.0          # overall multiplier on how much wallpaper colour the backgrounds get
                          # (0.7 = quieter, 1.3 = punchier)
WARM_DAMP = 0.25          # how much neutral tint is removed at the muddiest hue (yellow-green).
                          # Dark yellow/green tints can read as olive/brown sludge, blue/purple ones don't.
BRIGHT_L = 0.035          # extra lightness for the "bright" ANSI colours
BRIGHT_C = 1.05           # chroma multiplier for the bright ANSI colours

# role: (L, C, hue) -- based on Catppuccin Mocha
# Lightness of the palest roles is eased down a little so yellow/green/cyan don't wash out.
HUES = {
    "red":    (0.745, 0.140, 8),
    "orange": (0.815, 0.115, 53),
    "yellow": (0.860, 0.095, 88),
    "green":  (0.830, 0.120, 143),
    "cyan":   (0.840, 0.090, 205),
    "blue":   (0.766, 0.115, 260),
    "purple": (0.787, 0.122, 305),
}
# role: (L, C); hue comes from the wallpaper. These are the base, PALETTES restyle them for the others.
# Backgrounds carry a clear tint of the wallpaper but stay well short of "neon navy".
NEUTRALS = {
    "bg":     (0.255, 0.019),
    "bg2":    (0.295, 0.026),
    "bg3":    (0.355, 0.034),
    "black":  (0.385, 0.037),
    "muted2": (0.500, 0.042),
    "muted1": (0.735, 0.037),
    "fg":     (0.855, 0.030),
}


class Style(NamedTuple):
    """How a palette treats one group of roles. The defaults leave the group untouched."""
    chroma: float = 1.0  # Multiplier on the role's chroma
    hue: float = 0.0  # Degrees added to the role's hue
    tone: float = 1.0  # >1 - dark becomes darker, light becomes lighter. <1 - everything becomes more grey
    light: float = 0.0  # Added to the lightness, after tone
    pull: float = 1.0  # Accents only: multiplier on NUDGE_PULL and MAX_NUDGE, i.e. how far red, green... lean towards the wallpaper hue


# Role groups a Style can be given to (names as used in the palettes file)
SURFACE, TEXT, MUTED, ACCENT, PRIMARY, SECONDARY, TERTIARY = (
    "surface", "text", "muted", "accent", "primary", "secondary", "tertiary")
# surface = bg, bg2, bg3, black     text = fg, br_fg     muted = muted1, muted2 (also the bar border)
# accent  = red .. purple and their br_ versions
GROUPS = (SURFACE, TEXT, MUTED, ACCENT, PRIMARY, SECONDARY, TERTIARY)
GROUP_OF = {"bg": SURFACE, "bg2": SURFACE, "bg3": SURFACE, "black": SURFACE,
            "fg": TEXT, "muted1": MUTED, "muted2": MUTED}


class Palette(NamedTuple):
    name: str
    button: str  # Role the theme button is coloured with: "grey" or one of HUES
    lighten: float  # Theme.lighten
    styles: dict  # group -> Style, missing groups use Style()


# ----------------------------------------------------------------------------


def _lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _unlin(c):
    c = 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return c


def rgb_to_oklab(r, g, b):
    r, g, b = _lin(r), _lin(g), _lin(b)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def _oklab_to_lin(L, a, b):
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def lch_to_hex(L, C, h):
    """OKLCH -> #rrggbb, reducing chroma (never lightness/hue) until it fits in sRGB."""
    L = min(max(L, 0.0), 1.0)
    hr = math.radians(h)

    def fits(c):
        rgb = _oklab_to_lin(L, c * math.cos(hr), c * math.sin(hr))
        return all(-1e-4 <= v <= 1 + 1e-4 for v in rgb)

    if not fits(C):
        lo, hi = 0.0, C
        for _ in range(24):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if fits(mid) else (lo, mid)
        C = lo
    rgb = _oklab_to_lin(L, C * math.cos(hr), C * math.sin(hr))
    return "#" + "".join(f"{round(min(max(_unlin(max(v, 0.0)), 0.0), 1.0) * 255):02x}" for v in rgb)


def arc(a, b):
    """Signed shortest rotation from hue a to hue b, in (-180, 180]."""
    return (b - a + 180.0) % 360.0 - 180.0


def hue_damp(h):
    """1.0 for blue/purple (hue 280), falling to 1 - WARM_DAMP for yellow-green (hue 100).

    Low-chroma dark tints look rich in blue/purple but turn into olive/brown mud around
    yellow-green, so neutrals get less of the wallpaper's tint there.
    """
    return 1.0 - WARM_DAMP * (1.0 - math.cos(math.radians(h - 280.0))) / 2.0


def analyse(pixels):
    """Dominant vivid hue of a wallpaper, plus how vivid it is."""
    bins = [0.0] * 36
    pts = []
    for r, g, b in pixels:
        L, a, bb = rgb_to_oklab(r, g, b)
        C = math.hypot(a, bb)
        if C < 0.03 or L < 0.15 or L > 0.95:  # skip greys, near-black, near-white
            continue
        h = math.degrees(math.atan2(bb, a)) % 360
        w = C * C  # favour vivid pixels
        bins[int(h // 10)] += w
        pts.append((h, C, w))
    if not pts:
        return FALLBACK_HUE, 0.08
    sm = [bins[i - 1] + 2 * bins[i] + bins[(i + 1) % 36] for i in range(36)]
    peak = max(range(36), key=sm.__getitem__) * 10 + 5
    near = [(h, C, w) for h, C, w in pts if abs(arc(peak, h)) <= 30]
    sx = sum(w * math.cos(math.radians(h)) for h, _, w in near)
    sy = sum(w * math.sin(math.radians(h)) for h, _, w in near)
    tw = sum(w for _, _, w in near)
    return math.degrees(math.atan2(sy, sx)) % 360, sum(C * w for _, C, w in near) / tw


def parse_palettes(path):
    with open(path, "rb") as f:
        data = tomllib.load(f).get("palette", [])
    if not data:
        raise ValueError("no [[palette]] entries")
    pals = []
    for d in data:
        name = d.get("name", "?")
        extra = set(d) - {"name", "button", "lighten", *GROUPS}
        if extra:
            raise ValueError(f"{name}: unknown key(s) {', '.join(sorted(extra))}")
        if d.get("button", "grey") != "grey" and d["button"] not in HUES:
            raise ValueError(f"{name}: unknown button role {d['button']!r}")
        pals.append(Palette(d["name"], d.get("button", "grey"), d.get("lighten", 1.2),
                            {g: Style(**d[g]) for g in GROUPS if g in d}))
    return {i: p for i, p in enumerate(pals, 1)}


def load_palettes():
    """Personal palettes.toml if present and valid, otherwise the committed default."""
    if os.path.isfile(PERSONAL_PALETTES):
        try:
            return parse_palettes(PERSONAL_PALETTES)
        except Exception as e:
            print(f"theme-gen: ignoring {PERSONAL_PALETTES}: {type(e).__name__}: {e}", file=sys.stderr)
    return parse_palettes(DEFAULT_PALETTES)


def build(pal, hue, vivid):

    def style(group):
        return pal.styles.get(group, Style())

    def tone(L, s):
        return 0.5 + (L - 0.5) * s.tone + s.light

    k = min(1.0, vivid / 0.12)
    bg_tint = BG_CHROMA * (0.45 + 0.55 * k)  # How strongly backgrounds pick up the wallpaper hue
    fg_tint = 0.50 + 0.50 * k  # Text stays much closer to neutral
    p = {}

    def neutral(name, L, C, group, tint):
        s = style(group)
        h = hue + s.hue
        # Damp on the hue the colour really ends up with, a palette may have turned it into mud territory
        p[name] = lch_to_hex(tone(L, s), C * tint * hue_damp(h) * s.chroma, h)

    for name, (L, C) in NEUTRALS.items():
        group = GROUP_OF[name]
        neutral(name, L, C, group, bg_tint if group == SURFACE else fg_tint)
    neutral("br_fg", min(NEUTRALS["fg"][0] + 0.05, 0.97), NEUTRALS["fg"][1], TEXT, fg_tint)

    s = style(ACCENT)
    for name, (L, C, h) in HUES.items():
        reach = MAX_NUDGE * s.pull
        h2 = h + max(-reach, min(reach, NUDGE_PULL * s.pull * arc(h, hue))) + s.hue
        L, C = tone(L, s), C * s.chroma
        p[name] = lch_to_hex(L, C, h2)
        p["br_" + name] = lch_to_hex(min(L + BRIGHT_L, 0.95), C * BRIGHT_C, h2)

    # Material-style roles: primary = the wallpaper's own colour, secondary = a calmer
    # version of it, tertiary = a contrasting accent round the hue wheel (its Style.hue).
    cp = min(max(vivid, 0.07), 0.13)
    for name, group, dl, c in (("primary", PRIMARY, 0.0, cp),
                               ("secondary", SECONDARY, -0.05, max(cp * 0.5, 0.04)),
                               ("tertiary", TERTIARY, 0.0, cp)):
        s = style(group)
        p[name] = lch_to_hex(tone(0.76 + dl, s), c * s.chroma, (hue + s.hue) % 360.0)
    p["accent"] = p["primary"]  # Kept so existing templates keep working
    p["br_black"] = p["muted2"]
    p["grey"] = lch_to_hex(0.76, 0.012, hue)  # Near-neutral, only used for the theme button
    return p


PALETTE_KEYS = ["bg", "bg2", "bg3", "fg", "muted1", "muted2", "accent",
                "primary", "secondary", "tertiary",
                "red", "orange", "yellow", "green", "cyan", "blue", "purple"]


def render(template, pal):
    for k, val in pal.items():
        template = template.replace("{{" + k + "}}", val)
    return template


def main():
    palettes = load_palettes()
    img = Image.open(WALLPAPER).convert("RGB")
    img.thumbnail((96, 96))
    getpx = getattr(img, "get_flattened_data", None) or img.getdata
    hue, vivid = analyse(list(getpx()))
    for n, meta in palettes.items():
        pal = build(meta, hue, vivid)
        out = os.path.join(STATE_DIR, f"v{n}")
        os.makedirs(out, exist_ok=True)
        with open(os.path.join(out, "palette.json"), "w") as f:
            json.dump({"variant": n, "count": len(palettes), "name": meta.name,
                       "button": pal[meta.button], "lighten": meta.lighten,
                       **{k: pal[k] for k in PALETTE_KEYS}}, f, indent=2)
        for name in TEMPLATES:
            with open(os.path.join(EXTRA_DIR, name)) as f:
                text = f.read()
            with open(os.path.join(out, name), "w") as f:
                f.write(render(text, pal))
    print(f"wallpaper hue {hue:.0f} deg, vividness {vivid:.3f}")


if __name__ == "__main__":
    main()
