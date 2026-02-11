import json
import os
import subprocess
import tkinter as tk
from tkinter import messagebox

GESTURES_FPATH = os.path.expanduser("~/.config/hexecute/gestures.json")

GRID_COLS = 2
GRID_ROWS = 3
PER_PAGE = GRID_COLS * GRID_ROWS

LINE_WIDTH = 4
START_DOT_RADIUS = 8
CELL_PADDING = 20
LABEL_OFFSET = 16
LABEL_TOP_CLEARANCE = 28
ROUND_RADIUS = 64

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

BUTTON_BG = "#ffffff"
BUTTON_BORDER_COLOR = "#c7c7c7"
BUTTON_TEXT_COLOR = "#111111"
BUTTON_RADIUS = 12
BUTTON_BORDER_WIDTH = 2
BUTTON_HEIGHT = 56


def load_gestures(path):
    with open(path) as f:
        return json.load(f)


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


def draw_gesture(canvas, points, x0, y0, w, h, label, tag):
    label_id = canvas.create_text(
        x0 + w / 2,
        y0 - LABEL_OFFSET,
        text=label,
        font=("Arial", TEXT_SIZE),
        fill=LABEL_COLOR,
        tags=(tag,)
    )

    draw_round_rect(
        canvas,
        x0,
        y0,
        x0 + w,
        y0 + h,
        ROUND_RADIUS,
        fill=CELL_BG_COLOR,
        outline="",
        tags=(tag,)
    )

    pts = normalize_points(points, w, h)
    pts = [(x + x0, y + y0) for x, y in pts]

    flat = [coord for pt in pts for coord in pt]
    canvas.create_line(flat, width=LINE_WIDTH, fill=LINE_COLOR, tags=(tag,))

    sx, sy = pts[0]
    r = START_DOT_RADIUS
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


def build_page(canvas, gestures, page_w, page_h, label_index, select_callback):
    cell_w = page_w / GRID_COLS
    cell_h = page_h / GRID_ROWS

    for idx, data in enumerate(gestures):
        row = idx // GRID_COLS
        col = idx % GRID_COLS

        x0 = col * cell_w + CELL_PADDING
        y0 = row * cell_h + CELL_PADDING + LABEL_TOP_CLEARANCE
        w = cell_w - 2 * CELL_PADDING
        h = cell_h - 2 * CELL_PADDING - LABEL_TOP_CLEARANCE

        name = data["command"]
        points = data["templates"][0]

        tag = f"gesture_{id(data)}"
        label_id = draw_gesture(canvas, points, x0, y0, w, h, name, tag)
        label_index.append((name, canvas, label_id))
        canvas.tag_bind(tag, "<Button-1>", lambda _e, n=name: select_callback(n))


def main():
    root = tk.Tk()
    root.title("Gesture Preview")

    sidebar = tk.Frame(root, width=260, bg=PAGE_BG_COLOR)
    sidebar.grid(row=0, column=0, sticky="ns")
    sidebar.grid_propagate(False)

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
    search_label.pack(padx=10, pady=(12, 4), anchor="w")

    search_var = tk.StringVar()
    search_container, search_entry = build_rounded_entry(
        sidebar,
        search_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2
    )
    search_container.pack(padx=10, fill="x")

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
    search_info.pack(padx=10, pady=(6, 0), anchor="w")

    tk.Frame(sidebar, height=2, bg=SIDEBAR_BORDER_COLOR).pack(fill="x", padx=10, pady=12)

    new_label = tk.Label(
        sidebar,
        text="New Gesture",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )
    new_label.pack(padx=10, pady=(0, 4), anchor="w")

    new_var = tk.StringVar()
    new_container, new_entry = build_rounded_entry(
        sidebar,
        new_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2
    )
    new_container.pack(padx=10, fill="x")

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
    new_button.pack(padx=10, pady=(8, 0), fill="x")

    selected_section = tk.Frame(sidebar, bg=PAGE_BG_COLOR)
    selected_separator = tk.Frame(selected_section, height=2, bg=SIDEBAR_BORDER_COLOR)
    selected_label = tk.Label(
        selected_section,
        text="Selected Gesture",
        bg=PAGE_BG_COLOR,
        font=("Arial", SIDEBAR_TEXT_SIZE)
    )
    selected_var = tk.StringVar()
    selected_container, selected_entry = build_rounded_entry(
        selected_section,
        selected_var,
        ("Arial", SIDEBAR_TEXT_SIZE),
        SIDEBAR_TEXT_SIZE * 2,
        readonly=True
    )

    delete_button = RoundedButton(
        selected_section,
        text="Delete Gesture",
        command=None,
        font=("Arial", SIDEBAR_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR
    )

    edit_button = RoundedButton(
        selected_section,
        text="Edit Gesture",
        command=None,
        font=("Arial", SIDEBAR_TEXT_SIZE),
        height=BUTTON_HEIGHT,
        radius=BUTTON_RADIUS,
        bg_color=BUTTON_BG,
        border_color=BUTTON_BORDER_COLOR,
        border_width=BUTTON_BORDER_WIDTH,
        text_color=BUTTON_TEXT_COLOR
    )

    def show_selected_section():
        if not selected_section.winfo_ismapped():
            selected_section.pack(padx=0, pady=(12, 0), fill="x")

    def hide_selected_section():
        if selected_section.winfo_ismapped():
            selected_section.pack_forget()

    selected_separator.pack(fill="x", padx=10, pady=12)
    selected_label.pack(padx=10, pady=(0, 4), anchor="w")
    selected_container.pack(padx=10, fill="x")
    delete_button.pack(padx=10, pady=(8, 0), fill="x")
    edit_button.pack(padx=10, pady=(8, 0), fill="x")

    canvas = tk.Canvas(main_frame, highlightthickness=0, bg=PAGE_BG_COLOR)
    vscroll = tk.Scrollbar(main_frame, orient="vertical", command=canvas.yview)
    canvas.configure(yscrollcommand=vscroll.set)

    canvas.grid(row=0, column=0, sticky="nsew")
    vscroll.grid(row=0, column=1, sticky="ns")

    main_frame.grid_rowconfigure(0, weight=1)
    main_frame.grid_columnconfigure(0, weight=1)

    scroll_frame = tk.Frame(canvas, bg=PAGE_BG_COLOR)
    window_id = canvas.create_window((0, 0), window=scroll_frame, anchor="nw")

    def _on_frame_configure(_):
        canvas.configure(scrollregion=canvas.bbox("all"))

    def _on_canvas_configure(event):
        canvas.itemconfig(window_id, width=event.width)

    scroll_frame.bind("<Configure>", _on_frame_configure)
    canvas.bind("<Configure>", _on_canvas_configure)

    page_w, page_h = 794, 1123
    label_index = []

    def clear_pages():
        for child in scroll_frame.winfo_children():
            child.destroy()
        label_index.clear()

    def rebuild_pages():
        clear_pages()
        gestures = load_gestures(GESTURES_FPATH)
        for chunk in chunked(gestures, PER_PAGE):
            page = tk.Canvas(
                scroll_frame,
                width=page_w,
                height=page_h,
                bg="white",
                highlightthickness=1,
                highlightbackground=PAGE_BORDER_COLOR
            )
            page.pack(pady=10)
            build_page(page, chunk, page_w, page_h, label_index, set_selected)

    def set_selected(name):
        selected_var.set(name)
        show_selected_section()
        selected_entry.select_range(0, tk.END)

    def run_new_gesture():
        text = new_var.get().strip()
        if not text:
            return
        subprocess.run(["hexecute", "-learn", text], check=False)
        new_var.set("")
        rebuild_pages()

    def run_delete_gesture():
        text = selected_var.get().strip()
        if not text:
            return
        ok = messagebox.askyesno("Delete Gesture", f"Remove gesture '{text}'?")
        if ok:
            subprocess.run(["hexecute", "-remove", text], check=False)
            selected_var.set("")
            hide_selected_section()
            rebuild_pages()

    def run_edit_gesture():
        text = selected_var.get().strip()
        if not text:
            return
        ok = messagebox.askyesno("Edit Gesture", f"Relearn gesture '{text}'?")
        if ok:
            subprocess.run(["hexecute", "-remove", text], check=False)
            subprocess.run(["hexecute", "-learn", text], check=False)
            rebuild_pages()
            selected_var.set(text)
            show_selected_section()

    new_button.command = run_new_gesture
    delete_button.command = run_delete_gesture
    edit_button.command = run_edit_gesture

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
        if hasattr(event, "num"):
            canvas.yview_scroll(-3 if event.num == 4 else 3, "units")
        else:
            delta = getattr(event, "delta", 0)
            move = int(-1 * (delta / 120)) or (-1 if delta > 0 else 1)
            canvas.yview_scroll(move * 3, "units")

    canvas.bind_all("<MouseWheel>", _on_mousewheel)
    canvas.bind_all("<Button-4>", _on_mousewheel)
    canvas.bind_all("<Button-5>", _on_mousewheel)

    rebuild_pages()
    hide_selected_section()

    screen_w = root.winfo_screenwidth()
    screen_h = root.winfo_screenheight()
    desired_w = min(page_w + 320, int(screen_w * 0.95))
    desired_h = min(page_h + 200, int(screen_h * 0.9))
    root.geometry(f"{desired_w}x{desired_h}")

    root.mainloop()


if __name__ == "__main__":
    main()
