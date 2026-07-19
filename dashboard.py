#!/usr/bin/env python3
"""Personal Dashboard - Dark Theme, Always on Top, Right Corner"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import json
import os
import glob
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

CONFIG_PATH = r"C:\Users\asw\dashboard-config.json"
DATA_PATH = r"C:\Users\asw\dashboard-data.json"
WIDTH = 420
HEIGHT = 700


def load_json(path, default=None):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default or {}


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


class Dashboard:
    # Dark theme colors
    BG = "#1a1a2e"
    FG = "#e0e0e0"
    ACCENT = "#6c63ff"
    ACCENT2 = "#38b6ff"
    CARD = "#16213e"
    CARD_HOVER = "#1a2744"
    GREEN = "#4caf50"
    RED = "#f44336"
    YELLOW = "#ffc107"
    ORANGE = "#ff9800"
    SECTION_BG = "#0f3460"

    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Mein Dashboard")
        self.root.configure(bg=self.BG)
        self.root.overrideredirect(False)
        self.root.attributes("-topmost", True)
        self.root.attributes("-alpha", 0.95)
        self.root.resizable(True, True)

        # Position: right corner
        screen_w = self.root.winfo_screenwidth()
        x = screen_w - WIDTH - 20
        y = 50
        self.root.geometry(f"{WIDTH}x{HEIGHT}+{x}+{y}")

        # State
        self.expanded_sections = {}
        self.data = load_json(DATA_PATH, {"birthdays": [], "memorial": [], "todos": []})
        self.files_cache = []

        self._build_ui()
        self._refresh_files()
        self._refresh_clock()
        self._auto_refresh()

    def _build_ui(self):
        # Header
        header = tk.Frame(self.root, bg=self.ACCENT, height=50)
        header.pack(fill="x", side="top")
        header.pack_propagate(False)

        title = tk.Label(header, text=" Mein Dashboard", font=("Segoe UI", 14, "bold"),
                         bg=self.ACCENT, fg="white", anchor="w")
        title.pack(side="left", padx=15, pady=10)

        self.clock_label = tk.Label(header, text="", font=("Segoe UI", 11),
                                    bg=self.ACCENT, fg="white")
        self.clock_label.pack(side="right", padx=15, pady=10)

        # Date
        date_frame = tk.Frame(self.root, bg=self.BG)
        date_frame.pack(fill="x", padx=10, pady=(8, 4))
        now = datetime.now()
        days_mo = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        date_text = f"{days_mo[now.weekday()]}, {now.strftime('%d.%m.%Y')}"
        tk.Label(date_frame, text=date_text, font=("Segoe UI", 10),
                 bg=self.BG, fg=self.ACCENT2).pack(side="left")

        # Scrollable content
        container = tk.Frame(self.root, bg=self.BG)
        container.pack(fill="both", expand=True, padx=8, pady=4)

        canvas = tk.Canvas(container, bg=self.BG, highlightthickness=0)
        scrollbar = ttk.Scrollbar(container, orient="vertical", command=canvas.yview)
        self.content = tk.Frame(canvas, bg=self.BG)

        self.content.bind("<Configure>",
                          lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=self.content, anchor="nw", width=WIDTH - 30)
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        # Mouse wheel scroll
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        canvas.bind_all("<MouseWheel>", _on_mousewheel)

        # Build sections
        self._build_calendar_section()
        self._build_birthdays_section()
        self._build_memorial_section()
        self._build_files_section()
        self._build_todo_section()

    def _make_section(self, parent, title, icon, section_id):
        frame = tk.Frame(parent, bg=self.CARD, bd=0, highlightthickness=0)
        frame.pack(fill="x", pady=3, padx=2)

        header = tk.Frame(frame, bg=self.CARD)
        header.pack(fill="x")

        toggle_btn = tk.Label(header, text=f" {icon} {title}", font=("Segoe UI", 11, "bold"),
                              bg=self.CARD, fg=self.FG, cursor="hand2", anchor="w")
        toggle_btn.pack(fill="x", padx=10, pady=8)
        toggle_btn.bind("<Button-1>", lambda e: self._toggle_section(section_id))

        content = tk.Frame(frame, bg=self.SECTION_BG)
        content.pack(fill="x")
        content.pack_forget()  # Collapsed by default

        self.expanded_sections[section_id] = {"content": content, "visible": False}
        toggle_btn.bind("<Button-1>", lambda e, s=section_id, c=content, b=toggle_btn:
                        self._toggle_section(s, c, b))

        return content

    def _toggle_section(self, section_id, content=None, btn=None):
        if section_id not in self.expanded_sections:
            return
        info = self.expanded_sections[section_id]
        if info["visible"]:
            content.pack_forget()
            info["visible"] = False
        else:
            content.pack(fill="x")
            info["visible"] = True

    def _build_calendar_section(self):
        content = self._make_section(self.content, "Termine Today", "📅", "calendar")
        self.calendar_list = tk.Frame(content, bg=self.SECTION_BG)
        self.calendar_list.pack(fill="x", padx=10, pady=5)
        tk.Label(self.calendar_list, text="Keine Termine heute", font=("Segoe UI", 9),
                 bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

    def _build_birthdays_section(self):
        content = self._make_section(self.content, "Geburtstage", "🎂", "birthdays")
        self.birthday_list = tk.Frame(content, bg=self.SECTION_BG)
        self.birthday_list.pack(fill="x", padx=10, pady=5)
        self._refresh_birthdays()

        # Add button
        btn_frame = tk.Frame(content, bg=self.SECTION_BG)
        btn_frame.pack(fill="x", padx=10, pady=(0, 5))
        add_btn = tk.Label(btn_frame, text="+ Hinzufügen", font=("Segoe UI", 9, "underline"),
                           bg=self.SECTION_BG, fg=self.ACCENT2, cursor="hand2")
        add_btn.pack(side="left")
        add_btn.bind("<Button-1>", lambda e: self._add_birthday())

    def _add_birthday(self):
        win = tk.Toplevel(self.root)
        win.title("Geburtstag hinzufügen")
        win.configure(bg=self.BG)
        win.geometry("300x180+500+300")
        win.attributes("-topmost", True)

        tk.Label(win, text="Name:", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(10, 2))
        name_entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        name_entry.pack(fill="x", padx=15, pady=2)

        tk.Label(win, text="Datum (TT.MM.):", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(8, 2))
        date_entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        date_entry.pack(fill="x", padx=15, pady=2)

        def save():
            name = name_entry.get().strip()
            date = date_entry.get().strip()
            if name and date:
                self.data["birthdays"].append({"name": name, "date": date})
                save_json(DATA_PATH, self.data)
                self._refresh_birthdays()
                win.destroy()

        tk.Button(win, text="Speichern", command=save,
                  bg=self.ACCENT, fg="white", font=("Segoe UI", 10, "bold"),
                  relief="flat", padx=20, pady=5).pack(pady=15)

    def _refresh_birthdays(self):
        for w in self.birthday_list.winfo_children():
            w.destroy()
        bdays = self.data.get("birthdays", [])
        today = datetime.now().strftime("%d.%m.")
        found = False
        for b in bdays:
            marker = " <-- HEUTE!" if b["date"] == today else ""
            color = self.GREEN if b["date"] == today else self.FG
            tk.Label(self.birthday_list, text=f"{b['date']}  {b['name']}{marker}",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg=color,
                     anchor="w").pack(fill="x", pady=1)
            if b["date"] == today:
                found = True
        if not bdays:
            tk.Label(self.birthday_list, text="Keine Geburtstage eingetragen",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

    def _build_memorial_section(self):
        content = self._make_section(self.content, "Sterbetage", "🕯️", "memorial")
        self.memorial_list = tk.Frame(content, bg=self.SECTION_BG)
        self.memorial_list.pack(fill="x", padx=10, pady=5)
        tk.Label(self.memorial_list, text="Keine Sterbetage eingetragen",
                 font=("Segoe UI", 9), bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

        btn_frame = tk.Frame(content, bg=self.SECTION_BG)
        btn_frame.pack(fill="x", padx=10, pady=(0, 5))
        add_btn = tk.Label(btn_frame, text="+ Hinzufügen", font=("Segoe UI", 9, "underline"),
                           bg=self.SECTION_BG, fg=self.ACCENT2, cursor="hand2")
        add_btn.pack(side="left")
        add_btn.bind("<Button-1>", lambda e: self._add_memorial())

    def _add_memorial(self):
        win = tk.Toplevel(self.root)
        win.title("Sterbetag hinzufügen")
        win.configure(bg=self.BG)
        win.geometry("300x200+500+300")
        win.attributes("-topmost", True)

        tk.Label(win, text="Name:", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(10, 2))
        name_entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        name_entry.pack(fill="x", padx=15, pady=2)

        tk.Label(win, text="Datum (TT.MM.):", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(8, 2))
        date_entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        date_entry.pack(fill="x", padx=15, pady=2)

        tk.Label(win, text="Jahr (optional):", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(8, 2))
        year_entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        year_entry.pack(fill="x", padx=15, pady=2)

        def save():
            name = name_entry.get().strip()
            date = date_entry.get().strip()
            year = year_entry.get().strip()
            if name and date:
                entry = {"name": name, "date": date}
                if year:
                    entry["year"] = year
                self.data.setdefault("memorial", []).append(entry)
                save_json(DATA_PATH, self.data)
                self._refresh_memorial()
                win.destroy()

        tk.Button(win, text="Speichern", command=save,
                  bg=self.ACCENT, fg="white", font=("Segoe UI", 10, "bold"),
                  relief="flat", padx=20, pady=5).pack(pady=10)

    def _refresh_memorial(self):
        for w in self.memorial_list.winfo_children():
            w.destroy()
        entries = self.data.get("memorial", [])
        today = datetime.now().strftime("%d.%m.")
        for e in entries:
            year_str = f" ({e.get('year', '')})" if e.get('year') else ""
            marker = " <-- HEUTE" if e["date"] == today else ""
            color = self.ORANGE if e["date"] == today else self.FG
            tk.Label(self.memorial_list, text=f"{e['date']}{year_str}  {e['name']}{marker}",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg=color,
                     anchor="w").pack(fill="x", pady=1)
        if not entries:
            tk.Label(self.memorial_list, text="Keine Sterbetage eingetragen",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

    def _build_files_section(self):
        content = self._make_section(self.content, "Dateien", "📄", "files")
        self.files_list = tk.Frame(content, bg=self.SECTION_BG)
        self.files_list.pack(fill="x", padx=10, pady=5)

        btn_frame = tk.Frame(content, bg=self.SECTION_BG)
        btn_frame.pack(fill="x", padx=10, pady=(0, 5))
        refresh_btn = tk.Label(btn_frame, text="🔄 Aktualisieren", font=("Segoe UI", 9),
                               bg=self.SECTION_BG, fg=self.ACCENT2, cursor="hand2")
        refresh_btn.pack(side="left")
        refresh_btn.bind("<Button-1>", lambda e: self._refresh_files())

    def _refresh_files(self):
        for w in self.files_list.winfo_children():
            w.destroy()

        extensions = [".pdf", ".doc", ".docx", ".xls", ".xlsx"]
        search_paths = [
            Path.home() / "Documents",
            Path.home() / "Desktop",
            Path.home() / "Downloads",
        ]

        files = []
        for sp in search_paths:
            if sp.exists():
                for ext in extensions:
                    try:
                        for f in sp.rglob(f"*{ext}"):
                            if f.is_file():
                                files.append(f)
                    except PermissionError:
                        pass

        # Sort by modification time, newest first
        files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        files = files[:50]  # Limit to 50

        self.files_cache = files

        icons = {".pdf": "📕", ".doc": "📘", ".docx": "📘", ".xls": "📗", ".xlsx": "📗"}

        for f in files[:15]:  # Show top 15
            mtime = datetime.fromtimestamp(f.stat().st_mtime)
            age_days = (datetime.now() - mtime).days
            if age_days == 0:
                time_str = "heute"
            elif age_days == 1:
                time_str = "gestern"
            else:
                time_str = f"{age_days} Tage"

            icon = icons.get(f.suffix.lower(), "📄")
            name = f.name[:40]
            lbl = tk.Label(self.files_list, text=f"{icon} {name} ({time_str})",
                           font=("Segoe UI", 8), bg=self.SECTION_BG, fg=self.FG,
                           anchor="w", cursor="hand2")
            lbl.pack(fill="x", pady=0)
            lbl.bind("<Button-1>", lambda e, fp=f: os.startfile(str(fp)))

        if not files:
            tk.Label(self.files_list, text="Keine Dateien gefunden",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

        tk.Label(self.files_list, text=f"Gesamt: {len(files)} Dateien",
                 font=("Segoe UI", 8), bg=self.SECTION_BG, fg="#666").pack(anchor="w", pady=(3, 0))

    def _build_todo_section(self):
        content = self._make_section(self.content, "To-Do", "✅", "todo")
        self.todo_list = tk.Frame(content, bg=self.SECTION_BG)
        self.todo_list.pack(fill="x", padx=10, pady=5)
        self._refresh_todos()

        btn_frame = tk.Frame(content, bg=self.SECTION_BG)
        btn_frame.pack(fill="x", padx=10, pady=(0, 8))
        add_btn = tk.Label(btn_frame, text="+ Neue Aufgabe", font=("Segoe UI", 9, "underline"),
                           bg=self.SECTION_BG, fg=self.ACCENT2, cursor="hand2")
        add_btn.pack(side="left")
        add_btn.bind("<Button-1>", lambda e: self._add_todo())

    def _add_todo(self):
        win = tk.Toplevel(self.root)
        win.title("To-Do hinzufügen")
        win.configure(bg=self.BG)
        win.geometry("320x150+500+300")
        win.attributes("-topmost", True)

        tk.Label(win, text="Aufgabe:", bg=self.BG, fg=self.FG, font=("Segoe UI", 10)).pack(anchor="w", padx=15, pady=(12, 2))
        entry = tk.Entry(win, font=("Segoe UI", 10), bg=self.CARD, fg=self.FG, insertbackground=self.FG)
        entry.pack(fill="x", padx=15, pady=5)
        entry.focus()

        def save():
            text = entry.get().strip()
            if text:
                self.data.setdefault("todos", []).append({"text": text, "done": False, "created": datetime.now().isoformat()})
                save_json(DATA_PATH, self.data)
                self._refresh_todos()
                win.destroy()

        entry.bind("<Return>", lambda e: save())
        tk.Button(win, text="Hinzufügen", command=save,
                  bg=self.ACCENT, fg="white", font=("Segoe UI", 10, "bold"),
                  relief="flat", padx=20, pady=5).pack(pady=10)

    def _refresh_todos(self):
        for w in self.todo_list.winfo_children():
            w.destroy()
        todos = self.data.get("todos", [])

        for i, todo in enumerate(todos):
            frame = tk.Frame(self.todo_list, bg=self.SECTION_BG)
            frame.pack(fill="x", pady=1)

            var = tk.BooleanVar(value=todo.get("done", False))
            cb = tk.Checkbutton(frame, variable=var,
                                command=lambda idx=i, v=var: self._toggle_todo(idx, v),
                                bg=self.SECTION_BG, activebackground=self.SECTION_BG,
                                selectcolor=self.ACCENT, fg=self.FG)
            cb.pack(side="left")

            color = "#666" if todo.get("done") else self.FG
            font = ("Segoe UI", 9, "overstrike" if todo.get("done") else "normal")
            lbl = tk.Label(frame, text=todo["text"], font=font,
                           bg=self.SECTION_BG, fg=color, anchor="w")
            lbl.pack(side="left", fill="x", expand=True)

            del_btn = tk.Label(frame, text="✕", font=("Segoe UI", 9),
                               bg=self.SECTION_BG, fg=self.RED, cursor="hand2")
            del_btn.pack(side="right", padx=5)
            del_btn.bind("<Button-1>", lambda e, idx=i: self._delete_todo(idx))

        if not todos:
            tk.Label(self.todo_list, text="Keine Aufgaben",
                     font=("Segoe UI", 9), bg=self.SECTION_BG, fg="#888").pack(anchor="w", pady=3)

    def _toggle_todo(self, idx, var):
        todos = self.data.get("todos", [])
        if idx < len(todos):
            todos[idx]["done"] = var.get()
            save_json(DATA_PATH, self.data)
            self._refresh_todos()

    def _delete_todo(self, idx):
        todos = self.data.get("todos", [])
        if idx < len(todos):
            todos.pop(idx)
            save_json(DATA_PATH, self.data)
            self._refresh_todos()

    def _refresh_clock(self):
        now = datetime.now().strftime("%H:%M")
        try:
            self.clock_label.config(text=now)
        except Exception:
            pass

    def _auto_refresh(self):
        self._refresh_clock()
        try:
            self.root.after(30000, self._auto_refresh)  # Every 30s
        except Exception:
            pass

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    Dashboard().run()
