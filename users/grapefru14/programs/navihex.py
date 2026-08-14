import json
import math
import os
import subprocess
import tkinter as tk
import tkinter.font as tkfont
from tkinter import messagebox

GESTURES_FPATH = os.path.expanduser("~/.config/hexecute/gestures.json")

# The gesture grid is responsive: the number of columns is derived from
# the available page width (MIN_CELL_W..MAX_GRID_COLS), not fixed, so wide
# windows show more gestures per row and narrow windows show fewer.
GRID_ROWS = 3
MIN_CELL_W = 320
MAX_GRID_COLS = 5

LINE_WIDTH = 4
START_DOT_RADIUS = 8
CELL_PADDING = 20
LABEL_OFFSET = 18

# Card corner radius scales with the card's own size (see draw_gesture)
# instead of being one fixed pixel value, which used to make small
# thumbnails/icons look almost circular.
CARD_RADIUS_MIN = 8
CARD_RADIUS_MAX = 20
CARD_RADIUS_RATIO = 0.10
SCROLL = 2

# Reference aspect ratio for the gesture grid "pages" (based on the
# original fixed 794x1123 size). Pages are now sized dynamically to fill
# the available width, keeping this aspect ratio.
DEFAULT_PAGE_W = 794
DEFAULT_PAGE_H = 1123
PAGE_ASPECT = DEFAULT_PAGE_H / DEFAULT_PAGE_W

PAGE_BG_COLOR = "#f5f5f5"
PAGE_BORDER_COLOR = "#cfcfcf"
CELL_BG_COLOR = "#fef9f0"
LINE_COLOR = "#111111"
START_DOT_COLOR = "#d62828"
LABEL_COLOR = "#111111"
LABEL_HIGHLIGHT_COLOR = "#ffcc66"

TEXT_SIZE = 20
SIDEBAR_TEXT_SIZE = 30
SIDEBAR_BORDER_COLOR = "#bdbdbd"
SIDEBAR_INPUT_BG = "#ffffff"
SIDEBAR_INPUT_RADIUS = 12
SIDEBAR_INPUT_BORDER_COLOR = "#c7c7c7"
SIDEBAR_INPUT_BORDER_WIDTH = 2
SIDEBAR_INPUT_PAD_X = 14
SIDEBAR_INPUT_PAD_Y = 10
SIDEBAR_WIDTH = 440
SIDEBAR_PAD_X = 10
# Vertical gap between distinct sidebar sections (Search / New Gesture /
# Selected Gesture / Conflicts) -- the actual fix for "cramped vertically".
SIDEBAR_SECTION_GAP = 24
# Small dedicated font for the compact 3-across Rename/Edit/Delete row,
# independent of SIDEBAR_TEXT_SIZE so the short labels fit that width.
SIDEBAR_BUTTON_TEXT_SIZE = 16

BUTTON_BG = "#ffffff"
BUTTON_BORDER_COLOR = "#c7c7c7"
BUTTON_TEXT_COLOR = "#111111"
BUTTON_RADIUS = 12
BUTTON_BORDER_WIDTH = 2
BUTTON_HEIGHT = 56

# Tab bar styling (reuses the rounded-button look)
TAB_ACTIVE_BG = LABEL_HIGHLIGHT_COLOR
TAB_INACTIVE_BG = BUTTON_BG
TAB_WIDTH = 160

# --- Conflict detection tuning -------------------------------------------
# Per-pair similarity score (0-100) at/above which two gestures are
# considered to "conflict". This is the display cutoff mentioned in the
# spec: pairs below this are simply not shown anywhere.
CONFLICT_PAIR_CUTOFF = 55

# Number of points every gesture path is resampled to (arc-length spaced)
# before shape/direction comparison, so gestures recorded with different
# numbers of raw points are still comparable.
RESAMPLE_N = 32

# Row/thumbnail sizes on the Conflicts tab.
ROW_BIG_SIZE = 180
ROW_SMALL_SIZE = 90

# Small icon size used next to each conflict entry in the sidebar panel.
ICON_SIZE = 76

# Icon shown next to the currently selected gesture's name/rename field.
SELECTED_ICON_SIZE = 84

# Max visible height (px) of the scrollable sidebar conflicts list before
# it scrolls instead of growing and pushing other sidebar content down.
SIDEBAR_CONFLICTS_HEIGHT = 260


def load_gestures(path):
    with open(path) as f:
        js = json.load(f)
    js.sort(key=lambda x: x['command'])
    return js


def chunked(seq, size):
    for i in range(0, len(seq), size):
        yield seq[i:i + size]


def normalize_points(points, width, height, padding=20):
    xs = [p["X"] for p in points]
    ys = [p["Y"] for p in points]

    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)

    span_x = max_x - min_x or 1
    span_y = max_y - min_y or 1

    scale = min((width - 2 * padding) / span_x, (height - 2 * padding) / span_y)

    norm = []
    for p in points:
        x = (p["X"] - min_x) * scale + padding
        y = (p["Y"] - min_y) * scale + padding
        norm.append((x, y))
    return norm


# ---------------------------------------------------------------------------
# Conflict detection
#
# Two gestures are flagged as conflicting when their strokes are similar
# enough that the recognizer is likely to confuse them. That similarity is a
# blend of:
#   - overall shape (are the paths the same rough form once scaled to a
#     common size)
#   - start point (do they begin in roughly the same place within their own
#     bounding box)
#   - direction (do they travel the same way, step by step, not just end up
#     in the same place)
#   - point count (very different amounts of detail/complexity make two
#     gestures less likely to be mixed up even if the rough shape matches)
# ---------------------------------------------------------------------------

def resample_points_arc(points, n):
    """Resample a path to n evenly (by arc length) spaced points."""
    if not points:
        return []
    if len(points) == 1:
        return [points[0]] * n

    def path_length(pts):
        d = 0.0
        for i in range(1, len(pts)):
            d += math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1])
        return d

    total = path_length(points)
    if total == 0:
        return [points[0]] * n

    interval = total / (n - 1)
    pts = list(points)
    new_points = [pts[0]]
    D = 0.0
    i = 1
    while i < len(pts):
        x0, y0 = pts[i - 1]
        x1, y1 = pts[i]
        d = math.hypot(x1 - x0, y1 - y0)
        if (D + d) >= interval and d > 0:
            t = (interval - D) / d
            qx = x0 + t * (x1 - x0)
            qy = y0 + t * (y1 - y0)
            new_points.append((qx, qy))
            pts.insert(i, (qx, qy))
            D = 0.0
        else:
            D += d
        i += 1

    while len(new_points) < n:
        new_points.append(pts[-1])

    return new_points[:n]


def normalize_unit(points):
    """Translate to the origin and uniformly scale into a unit box,
    preserving aspect ratio (so shape AND relative start position survive)."""
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    span_x = max_x - min_x or 1
    span_y = max_y - min_y or 1
    scale = 1.0 / max(span_x, span_y)
    return [((x - min_x) * scale, (y - min_y) * scale) for x, y in points]


def gesture_similarity(raw_points_a, raw_points_b):
    """Return a 0-100 conflict/similarity score between two raw gesture
    point lists (each a list of {"X":..,"Y":..} dicts)."""
    p1 = [(p["X"], p["Y"]) for p in raw_points_a]
    p2 = [(p["X"], p["Y"]) for p in raw_points_b]

    n1 = normalize_unit(p1)
    n2 = normalize_unit(p2)

    r1 = resample_points_arc(n1, RESAMPLE_N)
    r2 = resample_points_arc(n2, RESAMPLE_N)

    # Shape: average distance between corresponding resampled points.
    point_dists = [math.hypot(a[0] - b[0], a[1] - b[1]) for a, b in zip(r1, r2)]
    shape_dist = sum(point_dists) / len(point_dists)
    shape_sim = max(0.0, 1.0 - shape_dist / 0.6)

    # Start point: distance between the first points of each normalized path.
    start_dist = math.hypot(r1[0][0] - r2[0][0], r1[0][1] - r2[0][1])
    start_sim = max(0.0, 1.0 - start_dist / 0.5)

    # Direction: how aligned the step-by-step travel direction is.
    def vectors(rp):
        return [(rp[i + 1][0] - rp[i][0], rp[i + 1][1] - rp[i][1]) for i in range(len(rp) - 1)]

    v1 = vectors(r1)
    v2 = vectors(r2)
    angle_sims = []
    for (ax, ay), (bx, by) in zip(v1, v2):
        la = math.hypot(ax, ay)
        lb = math.hypot(bx, by)
        if la == 0 or lb == 0:
            angle_sims.append(1.0)
            continue
        cos_sim = (ax * bx + ay * by) / (la * lb)
        cos_sim = max(-1.0, min(1.0, cos_sim))
        angle_sims.append((cos_sim + 1) / 2)
    direction_sim = sum(angle_sims) / len(angle_sims) if angle_sims else 1.0

    # Point count / complexity: very different raw point counts make the
    # gestures less likely to be confused for one another.
    c1, c2 = len(p1), len(p2)
    count_sim = 1.0 - (abs(c1 - c2) / max(c1, c2)) if max(c1, c2) else 1.0

    overall = (
        shape_sim * 0.50 +
        direction_sim * 0.25 +
        start_sim * 0.15 +
        count_sim * 0.10
    )
    return max(0.0, min(1.0, overall)) * 100.0


def compute_conflicts(gestures):
    """Return rows of (name, total_score, [(other_name, score), ...])
    for every gesture that has at least one conflict at/above
    CONFLICT_PAIR_CUTOFF, sorted by total_score descending."""
    items = [(g["command"], g["templates"][0]) for g in gestures]
    per_gesture = {name: [] for name, _ in items}

    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            name_a, pts_a = items[i]
            name_b, pts_b = items[j]
            score = gesture_similarity(pts_a, pts_b)
            if score >= CONFLICT_PAIR_CUTOFF:
                per_gesture[name_a].append((name_b, score))
                per_gesture[name_b].append((name_a, score))

    rows = []
    for name, conflicts in per_gesture.items():
        if not conflicts:
            continue
        conflicts.sort(key=lambda t: t[1], reverse=True)
        total = sum(s for _, s in conflicts)
        rows.append((name, total, conflicts))

    rows.sort(key=lambda r: r[1], reverse=True)
    return rows


def draw_round_rect(canvas, x0, y0, x1, y1, r, tags=(), **kwargs):
    r = min(r, (x1 - x0) / 2, (y1 - y0) / 2)
    fill = kwargs.pop("fill", "")
    outline = kwargs.pop("outline", "")
    width = kwargs.pop("width", 1)

    canvas.create_rectangle(
        x0 + r, y0,
        x1 - r, y1,
        fill=fill,
        outline="",
        tags=tags
    )
    canvas.create_rectangle(
        x0, y0 + r,
        x1, y1 - r,
        fill=fill,
        outline="",
        tags=tags
    )

    canvas.create_arc(
        x0, y0, x0 + 2 * r, y0 + 2 * r,
        start=90, extent=90,
        style=tk.PIESLICE, fill=fill, outline="",
        tags=tags
    )
    canvas.create_arc(
        x1 - 2 * r, y0, x1, y0 + 2 * r,
        start=0, extent=90,
        style=tk.PIESLICE, fill=fill, outline="",
        tags=tags
    )
    canvas.create_arc(
        x1 - 2 * r, y1 - 2 * r, x1, y1,
        start=270, extent=90,
        style=tk.PIESLICE, fill=fill, outline="",
        tags=tags
    )
    canvas.create_arc(
        x0, y1 - 2 * r, x0 + 2 * r, y1,
        start=180, extent=90,
        style=tk.PIESLICE, fill=fill, outline="",
        tags=tags
    )

    if outline:
        canvas.create_arc(
            x0, y0, x0 + 2 * r, y0 + 2 * r,
            start=90, extent=90,
            style=tk.ARC, outline=outline, width=width,
            tags=tags
        )
        canvas.create_arc(
            x1 - 2 * r, y0, x1, y0 + 2 * r,
            start=0, extent=90,
            style=tk.ARC, outline=outline, width=width,
            tags=tags
        )
        canvas.create_arc(
            x1 - 2 * r, y1 - 2 * r, x1, y1,
            start=270, extent=90,
            style=tk.ARC, outline=outline, width=width,
            tags=tags
        )
        canvas.create_arc(
            x0, y1 - 2 * r, x0 + 2 * r, y1,
            start=180, extent=90,
            style=tk.ARC, outline=outline, width=width,
            tags=tags
        )
        canvas.create_line(x0 + r, y0, x1 - r, y0, fill=outline, width=width, tags=tags)
        canvas.create_line(x0 + r, y1, x1 - r, y1, fill=outline, width=width, tags=tags)
        canvas.create_line(x0, y0 + r, x0, y1 - r, fill=outline, width=width, tags=tags)
        canvas.create_line(x1, y0 + r, x1, y1 - r, fill=outline, width=width, tags=tags)


class RoundedButton(tk.Canvas):
    def __init__(
        self,
        parent,
        text,
        command,
        font,
        height,
        radius,
        bg_color,
        border_color,
        border_width,
        text_color,
        **kwargs
    ):
        super().__init__(parent, height=height, highlightthickness=0, bg=PAGE_BG_COLOR, **kwargs)
        self.text = text
        self.command = command
        self.font = font
        self.height = height
        self.radius = radius
        self.bg_color = bg_color
        self.border_color = border_color
        self.border_width = border_width
        self.text_color = text_color
        self.bind("<Configure>", self._redraw)
        self.bind("<Button-1>", self._click)

    def _click(self, _event):
        if self.command:
            self.command()

    def set_active(self, active):
        """Used by tab buttons to toggle the active/inactive look."""
        self.bg_color = TAB_ACTIVE_BG if active else TAB_INACTIVE_BG
        self._redraw()

    def _redraw(self, _event=None):
        w = self.winfo_width()
        h = self.winfo_height()
        self.delete("all")
        draw_round_rect(
            self,
            0,
            0,
            w,
            h,
            self.radius,
            fill=self.bg_color,
            outline=self.border_color,
            width=self.border_width
        )
        self.create_text(
            w / 2,
            h / 2,
            text=self.text,
            font=self.font,
            fill=self.text_color
        )


class FlowLayout(tk.Frame):
    """A container that lays out fixed-width child widgets left-to-right,
    wrapping to a new row as needed, and automatically re-flows whenever
    the available width changes (window resize, sidebar toggling, etc.)."""

    def __init__(self, parent, item_width, h_pad=16, v_pad=16, **kwargs):
        super().__init__(parent, **kwargs)
        self.item_width = item_width
        self.h_pad = h_pad
        self.v_pad = v_pad
        self._items = []
        self.bind("<Configure>", self._reflow)

    def add_item(self, widget):
        self._items.append(widget)
        self._reflow()

    def clear(self):
        for w in self._items:
            w.destroy()
        self._items = []

    def _reflow(self, _event=None):
        width = self.winfo_width()
        if width <= 1:
            return
        col_w = self.item_width + self.h_pad
        cols = max(1, width // col_w)
        for idx, w in enumerate(self._items):
            r, c = divmod(idx, cols)
            w.grid(row=r, column=c, padx=self.h_pad // 2, pady=self.v_pad // 2, sticky="n")


def build_rounded_entry(parent, textvariable, font, height, readonly=False):
    container = tk.Canvas(parent, height=height, bg=PAGE_BG_COLOR, highlightthickness=0)
    inner = tk.Frame(container, bg=SIDEBAR_INPUT_BG)

    entry = tk.Entry(
        inner,
        textvariable=textvariable,
        font=font,
        bd=0,
        highlightthickness=0
    )

    if readonly:
        entry.configure(state="readonly", readonlybackground=SIDEBAR_INPUT_BG)

    entry.pack(fill="both", expand=True)

    entry_window_id = container.create_window(
        SIDEBAR_INPUT_PAD_X,
        SIDEBAR_INPUT_PAD_Y,
        anchor="nw",
        window=inner
    )

    def redraw(_event=None):
        w = container.winfo_width()
        h = container.winfo_height()
        container.delete("bg")

        draw_round_rect(
            container,
            0,
            0,
            w,
            h,
            SIDEBAR_INPUT_RADIUS,
            fill=SIDEBAR_INPUT_BG,
            outline=SIDEBAR_INPUT_BORDER_COLOR,
            width=SIDEBAR_INPUT_BORDER_WIDTH
        )
        container.tag_lower("bg")

        inner_w = max(0, w - (SIDEBAR_INPUT_PAD_X * 2))
        inner_h = max(0, h - (SIDEBAR_INPUT_PAD_Y * 2))
        container.itemconfig(entry_window_id, width=inner_w, height=inner_h)

    container.bind("<Configure>", redraw)
    redraw()

    return container, entry


_label_font_cache = {}


def _get_label_font(font_size):
    font_obj = _label_font_cache.get(font_size)
    if font_obj is None:
        font_obj = tkfont.Font(family="Arial", size=font_size)
        _label_font_cache[font_size] = font_obj
    return font_obj


def _wrap_label_lines(text, font_obj, max_width):
    words = text.split()
    if not words:
        return [""]

    lines = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if font_obj.measure(candidate) <= max_width:
            current = candidate
            continue

        if current:
            lines.append(current)
            current = ""

        if font_obj.measure(word) <= max_width:
            current = word
        else:
            # A single "word" (e.g. a long snake_case command name with no
            # spaces) is wider than the box on its own. Tk's canvas text
            # wrapping force-breaks it mid-word rather than overflowing, so
            # estimate that same character-level break here.
            chunk = ""
            for ch in word:
                test = chunk + ch
                if font_obj.measure(test) <= max_width or not chunk:
                    chunk = test
                else:
                    lines.append(chunk)
                    chunk = ch
            current = chunk

    if current:
        lines.append(current)

    return lines if lines else [""]


def label_clearance(label, font_size, max_width):
    """How much vertical space (including the gap down to the gesture box)
    a wrapped label needs above the drawing, given the box's width. Callers
    reserve this much room *before* calling draw_gesture so wrapped
    multi-line labels are never cut off."""
    font_obj = _get_label_font(font_size)
    lines = _wrap_label_lines(label, font_obj, max(1, int(max_width)))
    line_h = font_obj.metrics("linespace")
    return LABEL_OFFSET + len(lines) * line_h + (len(lines) - 1) * 2 + 4


def draw_gesture(canvas, points, x0, y0, w, h, label, tag, font_size=TEXT_SIZE, show_label=True, dot_radius=None):
    # anchor="s" + width=w means long labels wrap onto extra lines and grow
    # upward from the fixed baseline just above the gesture box. Callers
    # must have reserved label_clearance(label, font_size, w) of space
    # above y0 so the wrapped text has somewhere to go.
    if dot_radius is None:
        dot_radius = START_DOT_RADIUS

    label_id = None
    if show_label:
        label_id = canvas.create_text(
            x0 + w / 2,
            y0 - LABEL_OFFSET,
            text=label,
            font=("Arial", font_size),
            fill=LABEL_COLOR,
            width=max(1, int(w)),
            justify="center",
            anchor="s",
            tags=(tag,)
        )

    # Everything about the gesture "image" -- card background, path, and
    # start dot -- is drawn into a SQUARE region centered within the
    # available (possibly non-square) box, so resizing a non-square cell
    # never stretches the image into a rectangle.
    draw_size = min(w, h)
    draw_x0 = x0 + (w - draw_size) / 2
    draw_y0 = y0 + (h - draw_size) / 2

    # Corner radius scales with the card size instead of using one fixed
    # pixel value, so small icons get a subtle rounded-rectangle look
    # instead of turning into near-circles.
    radius = max(CARD_RADIUS_MIN, min(CARD_RADIUS_MAX, draw_size * CARD_RADIUS_RATIO))

    draw_round_rect(
        canvas,
        draw_x0,
        draw_y0,
        draw_x0 + draw_size,
        draw_y0 + draw_size,
        radius,
        fill=CELL_BG_COLOR,
        outline="",
        tags=(tag,)
    )

    pts = normalize_points(points, draw_size, draw_size)
    pts = [(x + draw_x0, y + draw_y0) for x, y in pts]

    flat = [coord for pt in pts for coord in pt]
    canvas.create_line(flat, width=LINE_WIDTH, fill=LINE_COLOR, tags=(tag,))

    sx, sy = pts[0]
    r = dot_radius
    canvas.create_oval(
        sx - r,
        sy - r,
        sx + r,
        sy + r,
        fill=START_DOT_COLOR,
        outline="",
        tags=(tag,)
    )

    return label_id


def make_gesture_thumb(parent, points, name, size, tag_prefix, on_click=None, font_size=None, show_label=True, dot_radius=None):
    """Build a small standalone canvas rendering a single gesture, with an
    optional click handler. Used on the Conflicts tab for both the large
    primary image and the smaller colliding-gesture images, and (without a
    label) as a compact icon in the sidebar."""
    if font_size is None:
        font_size = TEXT_SIZE if size >= 140 else max(11, TEXT_SIZE - 8)
    if dot_radius is None:
        dot_radius = max(3, round(size * 0.05))

    clearance = label_clearance(name, font_size, size) if show_label else 0
    total_h = size + clearance
    c = tk.Canvas(parent, width=size, height=total_h, bg=PAGE_BG_COLOR, highlightthickness=0)
    tag = f"{tag_prefix}_{id(points)}_{size}"
    draw_gesture(c, points, 0, clearance, size, size, name, tag, font_size=font_size, show_label=show_label, dot_radius=dot_radius)

    if on_click:
        c.tag_bind(tag, "<Button-1>", lambda _e: on_click())
        c.bind("<Button-1>", lambda _e: on_click())

    return c


def columns_for_width(page_w):
    """Number of grid columns the gesture page should use for a given
    page width, so cells stay comfortably sized instead of just being
    stretched or squeezed while the column count stays fixed."""
    return max(1, min(MAX_GRID_COLS, int(page_w // MIN_CELL_W)))


def build_page(canvas, gestures, page_w, page_h, cols, rows, label_index, select_callback):
    cell_w = page_w / cols
    cell_h = page_h / rows

    for idx, data in enumerate(gestures):
        row = idx // cols
        col = idx % cols

        w = cell_w - 2 * CELL_PADDING
        name = data["command"]
        points = data["templates"][0]

        clearance = label_clearance(name, TEXT_SIZE, w)
        x0 = col * cell_w + CELL_PADDING
        y0 = row * cell_h + CELL_PADDING + clearance
        h = max(40, cell_h - 2 * CELL_PADDING - clearance)

        tag = f"gesture_{id(data)}"
        label_id = draw_gesture(canvas, points, x0, y0, w, h, name, tag)
        label_index.append((name, canvas, label_id))
        canvas.tag_bind(tag, "<Button-1>", lambda _e, n=name: select_callback(n))


def build_conflicts_ui_from_rows(parent_frame, gestures, rows, select_callback):
    """Populate parent_frame with one row per gesture that has at least one
    conflict, sorted by total conflict weight (most important first).
    `rows` is the output of compute_conflicts(gestures)."""
    name_to_points = {g["command"]: g["templates"][0] for g in gestures}

    if not rows:
        tk.Label(
            parent_frame,
            text=f"No conflicts found (score >= {CONFLICT_PAIR_CUTOFF}).",
            bg=PAGE_BG_COLOR,
            fg="#555555",
            font=("Arial", TEXT_SIZE)
        ).pack(pady=30)
        return

    for name, total, conflicts in rows:
        points = name_to_points.get(name)
        if points is None:
            continue

        row_frame = tk.Frame(
            parent_frame,
            bg="white",
            highlightthickness=1,
            highlightbackground=PAGE_BORDER_COLOR
        )
        row_frame.pack(fill="x", padx=16, pady=8)

        left = tk.Frame(row_frame, bg="white")
        left.pack(side="left", padx=16, pady=16, anchor="n")

        big_thumb = make_gesture_thumb(
            left, points, name, ROW_BIG_SIZE, "conflict_primary",
            on_click=lambda n=name: select_callback(n)
        )
        big_thumb.pack()

        tk.Label(
            left,
            text=f"Total conflict score: {total:.0f}",
            bg="white",
            fg="#555555",
            font=("Arial", TEXT_SIZE - 4)
        ).pack(pady=(4, 0))

        divider = tk.Frame(row_frame, width=2, bg=PAGE_BORDER_COLOR)
        divider.pack(side="left", fill="y", pady=16)

        right = tk.Frame(row_frame, bg="white")
        right.pack(side="left", fill="both", expand=True, padx=16, pady=16)

        collider_wrap = FlowLayout(right, item_width=ROW_SMALL_SIZE, h_pad=20, v_pad=20, bg="white")
        collider_wrap.pack(fill="both", expand=True, anchor="w")

        for other_name, score in conflicts:
            other_points = name_to_points.get(other_name)
            if other_points is None:
                continue

            item = tk.Frame(collider_wrap, bg="white")

            small_thumb = make_gesture_thumb(
                item, other_points, other_name, ROW_SMALL_SIZE, "conflict_small",
                on_click=lambda n=other_name: select_callback(n)
            )
            small_thumb.pack()

            tk.Label(
                item,
                text=f"score: {score:.0f}",
                bg="white",
                fg="#b03030" if score >= 75 else "#555555",
                font=("Arial", TEXT_SIZE - 6)
            ).pack()

            collider_wrap.add_item(item)


def main():
    root = tk.Tk()
    root.title("Gesture Preview")

    sidebar = tk.Frame(root, width=SIDEBAR_WIDTH, bg=PAGE_BG_COLOR)
    sidebar.grid(row=0, column=0, sticky="ns")
    # sidebar's own children are pack()-managed, so pack_propagate (not
    # grid_propagate, which only governs grid-managed children) is what
    # actually locks it to SIDEBAR_WIDTH instead of growing to fit content.
    sidebar.pack_propagate(False)

    separator = tk.Frame(root, width=2, bg=SIDEBAR_BORDER_COLOR)
    separator.grid(row=0, column=1, sticky="ns")

    main_frame = tk.Frame(root, bg=PAGE_BG_COLOR)
    main_frame.grid(row=0, column=2, sticky="nsew")

    root.grid_rowconfigure(0, weight=1)
    root.grid_columnconfigure(2, weight=1)

    search_label = tk.Label(
        sidebar,
        text="Search Labels",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )
    search_label.pack(padx=SIDEBAR_PAD_X, pady=(16, 6), anchor="w")

    search_var = tk.StringVar()
    search_container, search_entry = build_rounded_entry(
        sidebar,
        search_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2
    )
    search_container.pack(padx=SIDEBAR_PAD_X, fill="x")

    def delete_prev_word(_):
        text = search_var.get()
        pos = search_entry.index(tk.INSERT)

        if pos == 0:
            return "break"

        i = pos - 1
        while i > 0 and text[i].isspace():
            i -= 1
        while i > 0 and not text[i - 1].isspace():
            i -= 1

        search_entry.delete(i, pos)
        return "break"

    search_entry.bind("<Control-BackSpace>", delete_prev_word)

    search_info = tk.Label(
        sidebar,
        text="",
        bg=PAGE_BG_COLOR,
        fg="#555555",
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )
    search_info.pack(padx=SIDEBAR_PAD_X, pady=(6, 0), anchor="w")

    tk.Frame(sidebar, height=2, bg=SIDEBAR_BORDER_COLOR).pack(
        fill="x", padx=SIDEBAR_PAD_X, pady=SIDEBAR_SECTION_GAP
    )

    new_label = tk.Label(
        sidebar,
        text="New Gesture",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )
    new_label.pack(padx=SIDEBAR_PAD_X, pady=(0, 6), anchor="w")

    new_var = tk.StringVar()
    new_container, new_entry = build_rounded_entry(
        sidebar,
        new_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2
    )
    new_container.pack(padx=SIDEBAR_PAD_X, fill="x")

    new_button = RoundedButton(
        sidebar,
        text="Run Learn",
        command=None,
        font=("Arial", SIDEBAR_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR
    )
    new_button.pack(padx=SIDEBAR_PAD_X, pady=(10, 0), fill="x")

    selected_section = tk.Frame(sidebar, bg=PAGE_BG_COLOR)
    selected_separator = tk.Frame(selected_section, height=2, bg=SIDEBAR_BORDER_COLOR)
    selected_label = tk.Label(
        selected_section,
        text="Selected Gesture",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )

    # A row with a small live preview icon of the selected gesture next to
    # its (editable, for renaming) name field.
    selected_row = tk.Frame(selected_section, bg=PAGE_BG_COLOR)
    selected_icon_holder = tk.Frame(selected_row, bg=PAGE_BG_COLOR)
    selected_icon_holder.pack(side="left", padx=(0, 10))

    selected_var = tk.StringVar()
    selected_container, selected_entry = build_rounded_entry(
        selected_row,
        selected_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2,
        readonly=False  # now editable for rename
    )
    selected_container.pack(side="left", fill="x", expand=True)

    def refresh_selected_icon(name):
        for child in selected_icon_holder.winfo_children():
            child.destroy()
        points = gesture_points_index["data"].get(name)
        if points is None:
            return
        icon = make_gesture_thumb(
            selected_icon_holder, points, name, SELECTED_ICON_SIZE, "sidebar_selected",
            show_label=False
        )
        icon.pack()

    button_row = tk.Frame(selected_section, bg=PAGE_BG_COLOR)

    rename_button = RoundedButton(
        button_row,
        text="Rename",
        command=None,
        font=("Arial", SIDEBAR_BUTTON_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR,
        width=1
    )

    edit_button = RoundedButton(
        button_row,
        text="Edit",
        command=None,
        font=("Arial", SIDEBAR_BUTTON_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR,
        width=1
    )

    delete_button = RoundedButton(
        button_row,
        text="Delete",
        command=None,
        font=("Arial", SIDEBAR_BUTTON_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR,
        width=1
    )

    # Shows the conflicts (if any) for whichever gesture is currently
    # selected, so conflicts can be resolved from either tab. This is a
    # small self-contained scrollable area (its own canvas + scrollbar)
    # capped at SIDEBAR_CONFLICTS_HEIGHT so a gesture with many conflicts
    # doesn't push the rest of the sidebar off-screen.
    conflicts_panel_separator = tk.Frame(selected_section, height=2, bg=SIDEBAR_BORDER_COLOR)
    conflicts_panel_label = tk.Label(
        selected_section,
        text="Conflicts",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )

    conflicts_panel_outer = tk.Frame(selected_section, bg=PAGE_BG_COLOR)
    conflicts_panel_canvas = tk.Canvas(
        conflicts_panel_outer,
        bg=PAGE_BG_COLOR,
        highlightthickness=0,
        height=SIDEBAR_CONFLICTS_HEIGHT
    )
    conflicts_panel_scrollbar = tk.Scrollbar(
        conflicts_panel_outer, orient="vertical", command=conflicts_panel_canvas.yview
    )
    conflicts_panel_canvas.configure(yscrollcommand=conflicts_panel_scrollbar.set)
    conflicts_panel_canvas.pack(side="left", fill="both", expand=True)
    conflicts_panel_scrollbar.pack(side="right", fill="y")

    conflicts_panel_list = tk.Frame(conflicts_panel_canvas, bg=PAGE_BG_COLOR)
    conflicts_panel_window = conflicts_panel_canvas.create_window((0, 0), window=conflicts_panel_list, anchor="nw")

    def _on_conflicts_panel_list_configure(_):
        conflicts_panel_canvas.configure(scrollregion=conflicts_panel_canvas.bbox("all"))

    def _on_conflicts_panel_canvas_configure(event):
        conflicts_panel_canvas.itemconfig(conflicts_panel_window, width=event.width)

    conflicts_panel_list.bind("<Configure>", _on_conflicts_panel_list_configure)
    conflicts_panel_canvas.bind("<Configure>", _on_conflicts_panel_canvas_configure)

    def _on_conflicts_panel_wheel(event):
        if hasattr(event, "num"):
            conflicts_panel_canvas.yview_scroll(-SCROLL if event.num == 4 else SCROLL, "units")
        else:
            delta = getattr(event, "delta", 0)
            move = int(-1 * (delta / 120)) or (-1 if delta > 0 else 1)
            conflicts_panel_canvas.yview_scroll(move * SCROLL, "units")
        # Without this, the event also reaches the app-wide "<MouseWheel>"
        # binding (bound via bind_all for the main content area) and scrolls
        # that too.
        return "break"

    def _bind_wheel_recursive(widget):
        widget.bind("<MouseWheel>", _on_conflicts_panel_wheel)
        widget.bind("<Button-4>", _on_conflicts_panel_wheel)
        widget.bind("<Button-5>", _on_conflicts_panel_wheel)
        for child in widget.winfo_children():
            _bind_wheel_recursive(child)

    _bind_wheel_recursive(conflicts_panel_canvas)

    selected_original_name = {"value": ""}
    conflicts_index = {"data": {}}
    gesture_points_index = {"data": {}}

    def show_selected_section():
        if not selected_section.winfo_ismapped():
            selected_section.pack(padx=0, pady=(12, 0), fill="x")

    def hide_selected_section():
        if selected_section.winfo_ismapped():
            selected_section.pack_forget()

    def refresh_conflicts_panel(name):
        for child in conflicts_panel_list.winfo_children():
            child.destroy()

        conflicts = conflicts_index["data"].get(name, [])

        if not conflicts:
            conflicts_panel_separator.pack_forget()
            conflicts_panel_label.pack_forget()
            conflicts_panel_outer.pack_forget()
            return

        conflicts_panel_separator.pack(fill="x", padx=SIDEBAR_PAD_X, pady=SIDEBAR_SECTION_GAP)
        conflicts_panel_label.pack(padx=SIDEBAR_PAD_X, pady=(0, 8), anchor="w")
        conflicts_panel_outer.pack(padx=SIDEBAR_PAD_X, fill="x")

        for other_name, score in conflicts:
            row = tk.Frame(conflicts_panel_list, bg=PAGE_BG_COLOR)
            row.pack(fill="x", pady=6)

            other_points = gesture_points_index["data"].get(other_name)
            if other_points is not None:
                icon = make_gesture_thumb(
                    row, other_points, other_name, ICON_SIZE, "sidebar_conflict",
                    on_click=lambda n=other_name: set_selected(n),
                    show_label=False
                )
                icon.pack(side="left", padx=(0, 8))

            name_btn = tk.Label(
                row,
                text=other_name,
                bg=PAGE_BG_COLOR,
                fg="#1a5fb4",
                font=("Arial", TEXT_SIZE - 4),
                cursor="hand2",
                anchor="w",
                justify="left",
                wraplength=150
            )
            name_btn.pack(side="left", fill="x", expand=True)
            name_btn.bind("<Button-1>", lambda _e, n=other_name: set_selected(n))

            tk.Label(
                row,
                text=f"{score:.0f}",
                bg=PAGE_BG_COLOR,
                fg="#b03030" if score >= 75 else "#555555",
                font=("Arial", TEXT_SIZE - 4)
            ).pack(side="right")

        _bind_wheel_recursive(conflicts_panel_list)

    selected_separator.pack(fill="x", padx=SIDEBAR_PAD_X, pady=SIDEBAR_SECTION_GAP)
    selected_label.pack(padx=SIDEBAR_PAD_X, pady=(0, 8), anchor="w")
    selected_row.pack(padx=SIDEBAR_PAD_X, fill="x")
    button_row.pack(padx=SIDEBAR_PAD_X, pady=(12, 0), fill="x")
    rename_button.pack(side="left", fill="x", expand=True, padx=(0, 6))
    edit_button.pack(side="left", fill="x", expand=True, padx=6)
    delete_button.pack(side="left", fill="x", expand=True, padx=(6, 0))

    # ------------------------------------------------------------------
    # Main content area: a tab bar (Gestures / Conflicts) on top, with the
    # two tab pages stacked in the same cell underneath and swapped via
    # tkraise(). The sidebar above is shared between both tabs.
    # ------------------------------------------------------------------
    main_frame.grid_rowconfigure(1, weight=1)
    main_frame.grid_columnconfigure(0, weight=1)

    tab_bar = tk.Frame(main_frame, bg=PAGE_BG_COLOR)
    tab_bar.grid(row=0, column=0, sticky="ew", padx=16, pady=(16, 8))

    content_frame = tk.Frame(main_frame, bg=PAGE_BG_COLOR)
    content_frame.grid(row=1, column=0, sticky="nsew")
    content_frame.grid_rowconfigure(0, weight=1)
    content_frame.grid_columnconfigure(0, weight=1)

    gestures_page_frame = tk.Frame(content_frame, bg=PAGE_BG_COLOR)
    conflicts_page_frame = tk.Frame(content_frame, bg=PAGE_BG_COLOR)
    gestures_page_frame.grid(row=0, column=0, sticky="nsew")
    conflicts_page_frame.grid(row=0, column=0, sticky="nsew")

    # --- Gestures tab: paginated grid canvas (existing behaviour) -------
    canvas = tk.Canvas(gestures_page_frame, highlightthickness=0, bg=PAGE_BG_COLOR)
    vscroll = tk.Scrollbar(gestures_page_frame, orient="vertical", command=canvas.yview)
    canvas.configure(yscrollcommand=vscroll.set)

    canvas.grid(row=0, column=0, sticky="nsew")
    vscroll.grid(row=0, column=1, sticky="ns")

    gestures_page_frame.grid_rowconfigure(0, weight=1)
    gestures_page_frame.grid_columnconfigure(0, weight=1)

    scroll_frame = tk.Frame(canvas, bg=PAGE_BG_COLOR)
    window_id = canvas.create_window((0, 0), window=scroll_frame, anchor="nw")

    # Pages are sized dynamically to fill the available canvas width
    # (keeping the original page's aspect ratio) instead of a fixed
    # 794px, so the layout uses the full window on wide screens and still
    # fits on narrow ones.
    page_size_state = {"w": DEFAULT_PAGE_W}
    resize_job = {"id": None}

    def _on_frame_configure(_):
        canvas.configure(scrollregion=canvas.bbox("all"))

    def _on_canvas_configure(event):
        canvas.itemconfig(window_id, width=event.width)

        new_w = max(200, event.width - 24)
        if abs(new_w - page_size_state["w"]) > 8:
            page_size_state["w"] = new_w
            if resize_job["id"] is not None:
                canvas.after_cancel(resize_job["id"])
            resize_job["id"] = canvas.after(150, rebuild_pages)

    scroll_frame.bind("<Configure>", _on_frame_configure)
    canvas.bind("<Configure>", _on_canvas_configure)

    # --- Conflicts tab: scrollable list of conflict rows -----------------
    conflicts_canvas = tk.Canvas(conflicts_page_frame, highlightthickness=0, bg=PAGE_BG_COLOR)
    conflicts_vscroll = tk.Scrollbar(conflicts_page_frame, orient="vertical", command=conflicts_canvas.yview)
    conflicts_canvas.configure(yscrollcommand=conflicts_vscroll.set)

    conflicts_canvas.grid(row=0, column=0, sticky="nsew")
    conflicts_vscroll.grid(row=0, column=1, sticky="ns")

    conflicts_page_frame.grid_rowconfigure(0, weight=1)
    conflicts_page_frame.grid_columnconfigure(0, weight=1)

    conflicts_scroll_frame = tk.Frame(conflicts_canvas, bg=PAGE_BG_COLOR)
    conflicts_window_id = conflicts_canvas.create_window((0, 0), window=conflicts_scroll_frame, anchor="nw")

    def _on_conflicts_frame_configure(_):
        conflicts_canvas.configure(scrollregion=conflicts_canvas.bbox("all"))

    def _on_conflicts_canvas_configure(event):
        conflicts_canvas.itemconfig(conflicts_window_id, width=event.width)

    conflicts_scroll_frame.bind("<Configure>", _on_conflicts_frame_configure)
    conflicts_canvas.bind("<Configure>", _on_conflicts_canvas_configure)

    current_canvas = {"value": canvas}

    # --- Tab bar buttons ---------------------------------------------------
    tab_gestures_btn = RoundedButton(
        tab_bar,
        text="Gestures",
        command=None,
        font=("Arial", SIDEBAR_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=TAB_ACTIVE_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR,
        width=TAB_WIDTH
    )
    tab_gestures_btn.pack(side="left", padx=(0, 8))

    tab_conflicts_btn = RoundedButton(
        tab_bar,
        text="Conflicts",
        command=None,
        font=("Arial", SIDEBAR_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=TAB_INACTIVE_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR,
        width=TAB_WIDTH
    )
    tab_conflicts_btn.pack(side="left")

    def show_tab(tab):
        if tab == "gestures":
            gestures_page_frame.tkraise()
            tab_gestures_btn.set_active(True)
            tab_conflicts_btn.set_active(False)
            current_canvas["value"] = canvas
        else:
            conflicts_page_frame.tkraise()
            tab_gestures_btn.set_active(False)
            tab_conflicts_btn.set_active(True)
            current_canvas["value"] = conflicts_canvas

    tab_gestures_btn.command = lambda: show_tab("gestures")
    tab_conflicts_btn.command = lambda: show_tab("conflicts")

    label_index = []

    def clear_pages():
        for child in scroll_frame.winfo_children():
            child.destroy()
        label_index.clear()

    def rebuild_pages():
        clear_pages()
        gestures = load_gestures(GESTURES_FPATH)
        page_w = page_size_state["w"]
        page_h = int(page_w * PAGE_ASPECT)
        cols = columns_for_width(page_w)
        per_page = cols * GRID_ROWS
        for chunk in chunked(gestures, per_page):
            page = tk.Canvas(
                scroll_frame,
                width=page_w,
                height=page_h,
                bg="white",
                highlightthickness=1,
                highlightbackground=PAGE_BORDER_COLOR
            )
            page.pack(pady=10)
            build_page(page, chunk, page_w, page_h, cols, GRID_ROWS, label_index, set_selected)

    def clear_conflicts():
        for child in conflicts_scroll_frame.winfo_children():
            child.destroy()

    def rebuild_conflicts():
        clear_conflicts()
        gestures = load_gestures(GESTURES_FPATH)
        gesture_points_index["data"] = {g["command"]: g["templates"][0] for g in gestures}
        rows = compute_conflicts(gestures)
        conflicts_index["data"] = {name: conflicts for name, _total, conflicts in rows}
        build_conflicts_ui_from_rows(conflicts_scroll_frame, gestures, rows, set_selected)

        current = selected_original_name["value"]
        if current:
            refresh_selected_icon(current)
            refresh_conflicts_panel(current)

    def rebuild_all():
        rebuild_pages()
        rebuild_conflicts()

    def set_selected(name):
        selected_original_name["value"] = name
        selected_var.set(name)
        show_selected_section()
        refresh_selected_icon(name)
        refresh_conflicts_panel(name)

    def run_new_gesture():
        text = new_var.get().strip()
        if not text:
            return
        subprocess.run(["hexecute", "-learn", text], check=False)
        new_var.set("")
        rebuild_all()

    def run_delete_gesture():
        text = selected_original_name["value"].strip()
        if not text:
            return
        ok = messagebox.askyesno("Delete Gesture", f"Remove gesture '{text}'?")
        if ok:
            subprocess.run(["hexecute", "-remove", text], check=False)
            selected_var.set("")
            selected_original_name["value"] = ""
            hide_selected_section()
            rebuild_all()

    def run_edit_gesture():
        text = selected_original_name["value"].strip()
        if not text:
            return
        ok = messagebox.askyesno("Edit Gesture", f"Relearn gesture '{text}'?")
        if ok:
            subprocess.run(["hexecute", "-remove", text], check=False)
            subprocess.run(["hexecute", "-learn", text], check=False)
            rebuild_all()
            selected_original_name["value"] = text
            selected_var.set(text)
            show_selected_section()

    def run_rename_gesture():
        old_name = selected_original_name["value"].strip()
        new_name = selected_var.get().strip()

        if not old_name:
            return
        if not new_name:
            messagebox.showerror("Rename Gesture", "New name cannot be empty.")
            return
        if new_name == old_name:
            return

        old_token = f'"command":"{old_name}"'
        new_token = f'"command":"{new_name}"'

        try:
            with open(GESTURES_FPATH, "r", encoding="utf-8") as f:
                content = f.read()
        except OSError as e:
            messagebox.showerror("Rename Gesture", f"Failed to read {GESTURES_FPATH}\n\n{e}")
            return

        occurrences = content.count(old_token)
        if occurrences == 0:
            messagebox.showerror(
                "Rename Gesture",
                f"Did not find {old_token} in:\n{GESTURES_FPATH}"
            )
            return

        if occurrences > 1:
            messagebox.showwarning(
                "Rename Gesture",
                f"Found {occurrences} instances of {old_token} in:\n{GESTURES_FPATH}\n\n"
                f"Only the first instance will be replaced."
            )

        updated = content.replace(old_token, new_token, 1)

        try:
            with open(GESTURES_FPATH, "w", encoding="utf-8") as f:
                f.write(updated)
        except OSError as e:
            messagebox.showerror("Rename Gesture", f"Failed to write {GESTURES_FPATH}\n\n{e}")
            return

        selected_original_name["value"] = new_name
        selected_var.set(new_name)
        rebuild_all()

    new_button.command = run_new_gesture
    delete_button.command = run_delete_gesture
    edit_button.command = run_edit_gesture
    rename_button.command = run_rename_gesture

    def clear_highlights():
        for _, c, label_id in label_index:
            c.itemconfig(label_id, fill=LABEL_COLOR)

    def scroll_to_canvas_item(item_canvas, item_id):
        item_canvas.update_idletasks()
        canvas.update_idletasks()

        ix0, iy0, ix1, iy1 = item_canvas.bbox(item_id)
        page_y = item_canvas.winfo_rooty() - scroll_frame.winfo_rooty()

        target_y = page_y + iy0 - 40
        total_h = canvas.bbox("all")[3]
        canvas.yview_moveto(max(0, target_y) / total_h)

    def perform_search(_=None):
        query = search_var.get().strip().lower()
        clear_highlights()

        if not query:
            search_info.config(text="")
            return

        matches = []
        for name, c, label_id in label_index:
            if query in name.lower():
                matches.append((name, c, label_id))
                c.itemconfig(label_id, fill=LABEL_HIGHLIGHT_COLOR)

        search_info.config(text=f"{len(matches)} match(es)")
        if matches:
            show_tab("gestures")
            _, c, label_id = matches[0]
            scroll_to_canvas_item(c, label_id)

    search_entry.bind("<Return>", perform_search)
    search_entry.bind("<KeyRelease>", perform_search)

    def focus_search(_):
        search_entry.focus_set()
        search_entry.select_range(0, tk.END)

    root.bind_all("<Control-f>", focus_search)

    def redirect_typing(event):
        widget_class = event.widget.winfo_class()
        if widget_class not in ("Entry", "Text"):
            if event.char and event.char.isprintable() and not (event.state & (0x4 | 0x8)):  # ignore Ctrl/Alt
                search_entry.focus_set()
                search_entry.insert("insert", event.char)
                perform_search()
                return "break"

    root.bind_all("<Key>", redirect_typing, add="+")  # type-to-search

    def _on_mousewheel(event):
        target = current_canvas["value"]
        if hasattr(event, "num"):
            target.yview_scroll(-SCROLL if event.num == 4 else SCROLL, "units")
        else:
            delta = getattr(event, "delta", 0)
            move = int(-1 * (delta / 120)) or (-1 if delta > 0 else 1)
            target.yview_scroll(move * SCROLL, "units")

    canvas.bind_all("<MouseWheel>", _on_mousewheel)
    canvas.bind_all("<Button-4>", _on_mousewheel)
    canvas.bind_all("<Button-5>", _on_mousewheel)

    rebuild_all()
    hide_selected_section()
    show_tab("gestures")

    screen_w = root.winfo_screenwidth()
    screen_h = root.winfo_screenheight()
    desired_w = min(DEFAULT_PAGE_W + SIDEBAR_WIDTH + 60, int(screen_w * 0.95))
    desired_h = min(DEFAULT_PAGE_H + 200, int(screen_h * 0.9))
    root.geometry(f"{desired_w}x{desired_h}")

    root.mainloop()


if __name__ == "__main__":
    main()
