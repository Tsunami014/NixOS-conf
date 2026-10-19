#!/usr/bin/env python3
"""theme-gen STATE_DIR TEMPLATE_DIR

Derives a colour scheme from a wallpaper and writes, config for each variant into STATE_DIR.

Lightness and chroma of every role are FIXED, the wallpaper only supplies the hue so colours can't come out pale or murky.
"""
import json
import math
import os
import sys

from PIL import Image

# ---------------------------------------------------------------- tuning knobs
FALLBACK_HUE = 275.0      # used for grey wallpapers
MAX_NUDGE = 12.0          # max degrees a role hue (red, green...) may rotate toward the wallpaper
BRIGHT_L = 0.045          # extra lightness for the "bright" ANSI colours
BRIGHT_C = 1.05           # chroma multiplier for the bright ANSI colours

# role: (L, C, hue) -- measured from Tokyo Night
HUES = {
    "red":    (0.723, 0.159, 10),
    "orange": (0.787, 0.137, 51),
    "yellow": (0.784, 0.106, 75),
    "green":  (0.795, 0.139, 130),
    "cyan":   (0.820, 0.105, 236),
    "blue":   (0.719, 0.132, 264),
    "purple": (0.751, 0.134, 299),
}
# role: (L, C); hue comes from the wallpaper
NEUTRALS = {
    "bg":     (0.226, 0.021),
    "bg2":    (0.267, 0.034),
    "bg3":    (0.329, 0.046),
    "black":  (0.360, 0.045),
    "muted2": (0.482, 0.050),
    "muted1": (0.728, 0.040),
    "fg":     (0.846, 0.028),
}
# per-variant adjustments
VARIANTS = {
    1: dict(bg=0.0,   fg=0.0,   muted1=0.0,   muted2=0.0,  acc_l=0.0,   acc_c=1.0),
    2: dict(bg=0.110, fg=0.015, muted1=-0.060, muted2=0.040, acc_l=0.025, acc_c=0.82),
}
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


def build(variant, hue, vivid):
    v = VARIANTS[variant]
    k = min(1.0, vivid / 0.12)
    bg_tint = 0.45 + 0.55 * k  # how strongly backgrounds pick up the wallpaper hue
    fg_tint = 0.50 + 0.50 * k  # text stays much closer to neutral
    p = {}
    for name, (L, C) in NEUTRALS.items():
        if name in ("bg", "bg2", "bg3", "black"):
            L += v["bg"]
        elif name in v:
            L += v[name]
        tint = bg_tint if name in ("bg", "bg2", "bg3", "black") else fg_tint
        p[name] = lch_to_hex(L, C * tint, hue)
    for name, (L, C, h) in HUES.items():
        h2 = h + max(-MAX_NUDGE, min(MAX_NUDGE, 0.5 * arc(h, hue)))
        L, C = L + v["acc_l"], C * v["acc_c"]
        p[name] = lch_to_hex(L, C, h2)
        p["br_" + name] = lch_to_hex(min(L + BRIGHT_L, 0.95), C * BRIGHT_C, h2)
    # Material-style roles: primary = the wallpaper's own colour, secondary = a calmer
    # version of it, tertiary = a contrasting accent 60 degrees round the hue wheel.
    lp = 0.76 + v["acc_l"]
    cp = min(max(vivid * 1.1, 0.08), 0.15) * v["acc_c"]
    p["primary"] = lch_to_hex(lp, cp, hue)
    p["secondary"] = lch_to_hex(lp - 0.05, max(cp * 0.5, 0.04), hue)
    p["tertiary"] = lch_to_hex(lp, cp * 0.9, (hue + 60.0) % 360.0)
    p["accent"] = p["primary"]                     # kept so existing templates keep working
    p["br_fg"] = lch_to_hex(min(NEUTRALS["fg"][0] + v["fg"] + 0.05, 0.97), NEUTRALS["fg"][1] * fg_tint, hue)
    p["br_black"] = p["muted2"]
    return p


PALETTE_KEYS = ["bg", "bg2", "bg3", "fg", "muted1", "muted2", "accent",
                "primary", "secondary", "tertiary",
                "red", "orange", "yellow", "green", "cyan", "blue", "purple"]


def render(template, pal):
    for k, val in pal.items():
        template = template.replace("{{" + k + "}}", val)
    return template


def main():
    state, tdir = sys.argv[1:3]
    img = Image.open(os.path.expanduser("~/Pictures/currentBg.jpg")).convert("RGB")
    img.thumbnail((96, 96))
    getpx = getattr(img, "get_flattened_data", None) or img.getdata
    hue, vivid = analyse(list(getpx()))
    for n in VARIANTS:
        pal = build(n, hue, vivid)
        out = os.path.join(state, f"v{n}")
        os.makedirs(out, exist_ok=True)
        with open(os.path.join(out, "palette.json"), "w") as f:
            json.dump({"variant": n, **{k: pal[k] for k in PALETTE_KEYS}}, f, indent=2)
        for name in ("alacritty.toml", "niri.kdl"):
            with open(os.path.join(tdir, name)) as f:
                text = f.read()
            with open(os.path.join(out, name), "w") as f:
                f.write(render(text, pal))
    print(f"wallpaper hue {hue:.0f} deg, vividness {vivid:.3f}")


if __name__ == "__main__":
    main()
