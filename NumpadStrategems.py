#!/usr/bin/env python3
"""
NumpadStrategems - Cross-platform Helldivers 2 Strategem Numpad
Works on Windows and Linux (KDE Wayland compatible via XWayland)

Usage:
    pip install -r requirements.txt
    python NumpadStrategems.py

On Linux/Wayland: pynput uses XWayland for global hotkeys.
You may need to be in the 'input' group for key listening:
    sudo usermod -aG input $USER
"""

import sys
import os
import re
import time
import html as html_module
import platform
import configparser
import shutil
import threading
import subprocess
import selectors
import hashlib
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Tuple

# ─── Third-party imports ────────────────────────────────────────────────────

try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QLabel, QPushButton, QCheckBox,
        QGridLayout, QVBoxLayout, QHBoxLayout, QFrame, QToolTip, QMessageBox,
        QDialog, QSizePolicy, QScrollArea, QSpacerItem
    )
    from PyQt6.QtCore import (
        Qt, QTimer, QThread, pyqtSignal, QPoint, QSize, QRect, QEvent
    )
    from PyQt6.QtGui import (
        QPixmap, QImage, QColor, QFont, QPainter, QIcon, QCursor,
        QPalette, QPolygon, QPen, QBrush
    )
except ImportError:
    print("PyQt6 is required. Install with: pip install PyQt6")
    sys.exit(1)

try:
    import requests
except ImportError:
    print("requests is required. Install with: pip install requests")
    sys.exit(1)

try:
    from PIL import Image as PILImage, ImageDraw
except ImportError:
    print("Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

# pynput is optional – used for global hotkeys on Windows
try:
    from pynput import keyboard as pynput_keyboard
    from pynput.keyboard import Key as PynputKey, Controller as KeyboardController, KeyCode
    HAS_PYNPUT = True
except ImportError:
    HAS_PYNPUT = False

# evdev is used for global hotkeys on Linux (works on Wayland)
try:
    import evdev
    from evdev import ecodes as ec
    HAS_EVDEV = True
except ImportError:
    HAS_EVDEV = False

# ─── Constants ──────────────────────────────────────────────────────────────

SCRIPT_NAME = "NumpadStrategems"
STEAM_URL = "https://steamcommunity.com/sharedfiles/filedetails/?id=3161075951"

# Direction code image URL → letter mapping
CODE_MAP = {
    "https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/": "U",
    "https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/": "D",
    "https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/": "L",
    "https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/": "R",
}

# Reference colours for icon classification (name → RGB)
COLOR_REFS = {
    "Green": (102, 147, 81),   # #669351
    "Blue":  (72, 171, 199),   # #48ABC7
    "Red":   (220, 122, 107),  # #DC7A6B
}
COLOR_TOLERANCE = 60

ITEMS_PER_ROW = 15
ICON_SIZE = 50
ICON_SPACING = 5
DARK_BG = "#1e1e1e"
DARK_BG_RGB = (30, 30, 30)

# Numpad virtual-key → button id maps  (pynput key.vk values)
if platform.system() == "Windows":
    _NUMPAD_VK_MAP = {
        96: "0", 97: "1", 98: "2", 99: "3", 100: "4",
        101: "5", 102: "6", 103: "7", 104: "8", 105: "9",
        106: "*", 107: "+", 109: "-", 110: ".", 111: "/",
        13: "Enter",
    }
else:
    _NUMPAD_VK_MAP = {
        # NumLock ON
        65456: "0", 65457: "1", 65458: "2", 65459: "3", 65460: "4",
        65461: "5", 65462: "6", 65463: "7", 65464: "8", 65465: "9",
        65450: "*", 65451: "+", 65453: "-", 65454: ".", 65455: "/",
        65421: "Enter",
        # NumLock OFF
        65438: "0", 65436: "1", 65433: "2", 65435: "3", 65430: "4",
        65437: "5", 65432: "6", 65429: "7", 65431: "8", 65434: "9",
    }

# Arrow key maps for code execution (pynput – Windows)
_ARROW_KEYS = {"U": PynputKey.up, "D": PynputKey.down, "L": PynputKey.left, "R": PynputKey.right} if HAS_PYNPUT else {}
_WASD_KEYS = {"U": "w", "D": "s", "L": "a", "R": "d"}

# evdev keycode maps (Linux)
_EV_NUMPAD_MAP = {
    82: "0", 79: "1", 80: "2", 81: "3", 75: "4",
    76: "5", 77: "6", 71: "7", 72: "8", 73: "9",
    83: ".", 98: "/", 55: "*", 74: "-", 78: "+", 96: "Enter",
}
_EV_CTRL_CODES = {29, 97}  # KEY_LEFTCTRL, KEY_RIGHTCTRL
_EV_ARROW_KEYS = {"U": 103, "D": 108, "L": 105, "R": 106}
_EV_WASD_KEYS = {"U": 17, "D": 31, "L": 30, "R": 32}  # W, S, A, D


# ─── Platform utilities ────────────────────────────────────────────────────

def get_data_dir() -> Path:
    """Return the platform-appropriate data directory."""
    if platform.system() == "Windows":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    return base / SCRIPT_NAME


def safe_filename(name: str) -> str:
    """Sanitise a strategem name for use as a filename."""
    return re.sub(r'[<>:"/\\|?*]', '_', name)


def strip_html(text: str) -> str:
    """Strip HTML tags and decode entities."""
    text = re.sub(r'<[^>]+>', '', text)
    return html_module.unescape(text).strip()


# ─── Data model ─────────────────────────────────────────────────────────────

@dataclass
class Strategem:
    name: str
    code: str = ""
    warbond: str = "General"
    color: str = "Yellow"
    icon_url: str = ""


# ─── Settings ───────────────────────────────────────────────────────────────

class Settings:
    """Manages INI-based settings with case-sensitive keys."""

    def __init__(self, path: Path):
        self.path = path
        self.config = configparser.ConfigParser(interpolation=None)
        self.config.optionxform = str  # preserve case
        if self.path.exists():
            self.config.read(str(self.path))
        else:
            self._create_defaults()

    def _create_defaults(self):
        self.config["Settings"] = {
            "AutoClose": "1",
            "KeyDelayMS": "67",
            "TestMode": "0",
        }
        self.config["Numpad"] = {
            "AlwaysOnTop": "0",
            "ArrowKeys": "1",
        }
        self.config["GUI"] = {}
        self.save()

    def save(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.path, "w") as f:
            self.config.write(f)

    def get(self, section: str, key: str, default: str = "") -> str:
        return self.config.get(section, key, fallback=default)

    def getint(self, section: str, key: str, default: int = 0) -> int:
        try:
            return int(self.get(section, key, str(default)))
        except ValueError:
            return default

    def getbool(self, section: str, key: str, default: bool = False) -> bool:
        return self.getint(section, key, int(default)) != 0

    def set(self, section: str, key: str, value):
        if not self.config.has_section(section):
            self.config.add_section(section)
        self.config.set(section, key, str(value))
        self.save()


class StrategemDB:
    """Manages Strategems.ini and assignments.ini."""

    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.ini_path = data_dir / "Strategems.ini"
        self.assignments_path = data_dir / "assignments.ini"
        self._cfg = configparser.ConfigParser(interpolation=None)
        self._cfg.optionxform = str
        self._assign_cfg = configparser.ConfigParser(interpolation=None)
        self._assign_cfg.optionxform = str
        self.reload()

    def reload(self):
        self._cfg = configparser.ConfigParser(interpolation=None)
        self._cfg.optionxform = str
        if self.ini_path.exists():
            self._cfg.read(str(self.ini_path))
        self._assign_cfg = configparser.ConfigParser(interpolation=None)
        self._assign_cfg.optionxform = str
        if self.assignments_path.exists():
            self._assign_cfg.read(str(self.assignments_path))

    # Strategem data
    def sections(self) -> List[str]:
        return [s for s in self._cfg.sections() if s != "__None__"]

    def get(self, name: str, key: str, default: str = "") -> str:
        return self._cfg.get(name, key, fallback=default)

    def set_strat(self, name: str, key: str, value: str):
        if not self._cfg.has_section(name):
            self._cfg.add_section(name)
        self._cfg.set(name, key, value)
        with open(self.ini_path, "w") as f:
            self._cfg.write(f)

    def save_strategems(self, strategems: List[Strategem]):
        """Write full strategem list to INI."""
        self._cfg = configparser.ConfigParser(interpolation=None)
        self._cfg.optionxform = str
        for s in strategems:
            self._cfg.add_section(s.name)
            self._cfg.set(s.name, "Code", s.code)
            self._cfg.set(s.name, "Warbond", s.warbond)
            if s.color:
                self._cfg.set(s.name, "Color", s.color)
        with open(self.ini_path, "w") as f:
            self._cfg.write(f)

    def load_strategems(self) -> List[Strategem]:
        result = []
        for name in self.sections():
            result.append(Strategem(
                name=name,
                code=self.get(name, "Code"),
                warbond=self.get(name, "Warbond", "General"),
                color=self.get(name, "Color", "Yellow"),
            ))
        return result

    # Assignments
    def get_assignment(self, button_key: str) -> str:
        return self._assign_cfg.get("Assignments", button_key, fallback="")

    def set_assignment(self, button_key: str, strategem_name: str):
        if not self._assign_cfg.has_section("Assignments"):
            self._assign_cfg.add_section("Assignments")
        self._assign_cfg.set("Assignments", button_key, strategem_name)
        with open(self.assignments_path, "w") as f:
            self._assign_cfg.write(f)

    def all_assignments(self) -> Dict[str, str]:
        if not self._assign_cfg.has_section("Assignments"):
            return {}
        return dict(self._assign_cfg.items("Assignments"))

    def find_assignment_for(self, strategem_name: str) -> str:
        """Return button key assigned to this strategem, or ''."""
        for k, v in self.all_assignments().items():
            if v == strategem_name:
                return k
        return ""


# ─── Image utilities ────────────────────────────────────────────────────────

def create_placeholder(width: int, height: int, path: Path):
    """Create a dark placeholder PNG."""
    img = PILImage.new("RGB", (width, height), DARK_BG_RGB)
    img.save(str(path))


def create_arrow_images(arrow_dir: Path):
    """Generate simple white triangle arrow PNGs."""
    arrow_dir.mkdir(parents=True, exist_ok=True)
    size = 20
    arrows = {
        "up":    [(size // 2, 2), (2, size - 2), (size - 2, size - 2)],
        "down":  [(size // 2, size - 2), (2, 2), (size - 2, 2)],
        "left":  [(2, size // 2), (size - 2, 2), (size - 2, size - 2)],
        "right": [(size - 2, size // 2), (2, 2), (2, size - 2)],
    }
    for name, pts in arrows.items():
        p = arrow_dir / f"{name}.png"
        if p.exists():
            continue
        img = PILImage.new("RGBA", (size, size), (0, 0, 0, 0))
        ImageDraw.Draw(img).polygon(pts, fill=(255, 255, 255, 255))
        img.save(str(p))


def detect_icon_color(icon_path: str) -> str:
    """Sample pixels to classify an icon as Yellow/Red/Green/Blue."""
    try:
        img = PILImage.open(icon_path).convert("RGBA")
        w, h = img.size
        step_x = max(1, w // 10)
        step_y = max(1, h // 10)
        counts = {"Green": 0, "Blue": 0, "Red": 0, "Yellow": 0}

        for y in range(0, h, step_y):
            for x in range(0, w, step_x):
                r, g, b, a = img.getpixel((x, y))
                if a < 128:
                    continue
                if max(r, g, b) < 50:
                    continue
                if r > 200 and g > 200 and b > 200:
                    continue
                diffs = {
                    cn: abs(r - cr) + abs(g - cg) + abs(b - cb)
                    for cn, (cr, cg, cb) in COLOR_REFS.items()
                }
                best = min(diffs, key=diffs.get)
                if diffs[best] < COLOR_TOLERANCE:
                    counts[best] += 1
                else:
                    counts["Yellow"] += 1

        total = sum(counts.values())
        if total == 0:
            return "Yellow"
        return max(counts, key=counts.get)
    except Exception:
        return "Yellow"


def scale_icon_to_button(source: str, width: int, height: int, dest: str):
    """Create a scaled+letterboxed version of an icon for non-square buttons."""
    try:
        src = PILImage.open(source).convert("RGBA")
        bg = PILImage.new("RGBA", (width, height), (*DARK_BG_RGB, 255))
        # Calculate fit with 2px margin
        sw, sh = src.size
        scale = min((width - 4) / sw, (height - 4) / sh)
        nw, nh = int(sw * scale), int(sh * scale)
        resized = src.resize((nw, nh), PILImage.LANCZOS)
        ox, oy = (width - nw) // 2, (height - nh) // 2
        bg.paste(resized, (ox, oy), resized)
        bg.save(dest)
    except Exception:
        pass


# ─── Init worker (background thread) ───────────────────────────────────────

class InitWorker(QThread):
    html_progress = pyqtSignal(str)
    ini_progress = pyqtSignal(str)
    icon_progress = pyqtSignal(str)
    download_progress = pyqtSignal(str)
    finished = pyqtSignal(bool)  # success

    def __init__(self, data_dir: Path, db: StrategemDB, parent=None):
        super().__init__(parent)
        self.data_dir = data_dir
        self.db = db
        self.icon_dir = data_dir / "icons"
        self.strategems: List[Strategem] = []

    def run(self):
        try:
            # 1. HTML download
            was_downloaded = self._grab_html()

            # 2. Placeholders
            self.icon_progress.emit("Placeholder Generation: Creating...")
            self._ensure_placeholders()
            create_arrow_images(self.icon_dir / "arrows")
            self.icon_progress.emit("Placeholder Generation: Complete")

            # 3. Parse if needed
            if was_downloaded or not self.db.ini_path.exists():
                self._parse_html()
                if not self._all_icons_organized():
                    self._download_icons()
                    self._detect_colors()
                    self._organize_icons()
                else:
                    self.download_progress.emit("Icon Download: Complete (cached)")
            else:
                self.ini_progress.emit("DB Generation: Skipped (cached)")
                self.strategems = self.db.load_strategems()

            # 4. Check missing icons
            self._check_missing_icons()

            self.finished.emit(True)
        except Exception as exc:
            self.ini_progress.emit(f"ERROR: {exc}")
            self.finished.emit(False)

    # ── helpers ──

    def _grab_html(self) -> bool:
        html_path = self.data_dir / "StrategmsRaw.html"
        need_download = not html_path.exists()
        if not need_download:
            mtime = datetime.fromtimestamp(html_path.stat().st_mtime)
            need_download = (datetime.now() - mtime) > timedelta(days=7)

        if need_download:
            self.html_progress.emit("HTML Download: Downloading from Steam...")
            try:
                resp = requests.get(STEAM_URL, timeout=30)
                resp.raise_for_status()
                html_path.write_bytes(resp.content)
                self.html_progress.emit("HTML Download: Complete")
                return True
            except Exception as e:
                self.html_progress.emit(f"HTML Download: Failed ({e})")
                return False
        else:
            self.html_progress.emit("HTML Download: Using cached version")
            return False

    def _ensure_placeholders(self):
        self.icon_dir.mkdir(parents=True, exist_ok=True)
        for name, w, h in [("placeholder.png", 50, 50),
                           ("placeholder_wide.png", 105, 50),
                           ("placeholder_tall.png", 50, 105)]:
            p = self.icon_dir / name
            if not p.exists():
                create_placeholder(w, h, p)

    def _parse_html(self):
        self.ini_progress.emit("DB Generation: Reading HTML...")
        html_path = self.data_dir / "StrategmsRaw.html"
        if not html_path.exists():
            self.ini_progress.emit("DB Generation: No HTML file")
            return
        html = html_path.read_text(encoding="utf-8", errors="replace")
        if not html:
            self.ini_progress.emit("DB Generation: Empty HTML")
            return

        # Collect section positions
        section_regex = re.compile(r'<div class="subSectionTitle">\s*(.*?)\s*</div>', re.DOTALL)
        section_map: List[Tuple[int, str]] = []
        for m in section_regex.finditer(html):
            title = strip_html(m.group(1))
            if title and title not in ("Intro", "Overview", "Credits", "Log"):
                section_map.append((m.start(), title))

        row_regex = re.compile(
            r'<div class="bb_table_tr">((?:<div class="bb_table_td">.*?</div>)*)</div>',
            re.DOTALL,
        )
        td_regex = re.compile(r'<div class="bb_table_td">(.*?)</div>', re.DOTALL)
        img_regex = re.compile(r'<img[^>]+src="([^"]+)"')
        href_regex = re.compile(r'<a[^>]+href="([^"]+)"')

        strategems: List[Strategem] = []
        current_category = "General"
        count = 0

        self.ini_progress.emit("DB Generation: Parsing...")
        for row_match in row_regex.finditer(html):
            pos = row_match.start()
            # Update category
            for sp, st in section_map:
                if sp < pos:
                    current_category = st
                else:
                    break

            row_html = row_match.group(1)
            if '<div class="bb_table_th">' in row_html:
                continue

            cells = [m.group(1) for m in td_regex.finditer(row_html)]
            if len(cells) < 3:
                continue

            name = strip_html(cells[1])
            if not name:
                continue

            icon_url = ""
            href_m = href_regex.search(cells[0])
            if href_m:
                icon_url = href_m.group(1)

            code = ""
            for img_m in img_regex.finditer(cells[2]):
                d = CODE_MAP.get(img_m.group(1), "")
                code += d

            strategems.append(Strategem(
                name=name, code=code, warbond=current_category,
                color="Yellow", icon_url=icon_url,
            ))
            count += 1
            if count % 10 == 0:
                self.ini_progress.emit(f"DB Generation: {count} strategems...")

        self.strategems = strategems
        self.db.save_strategems(strategems)
        self.ini_progress.emit(f"DB Generation: Complete ({count} strategems)")

    def _download_icons(self):
        self.download_progress.emit("Icon Download: Starting...")
        self.icon_dir.mkdir(parents=True, exist_ok=True)
        total = len(self.strategems)
        downloaded = skipped = 0

        for i, s in enumerate(self.strategems):
            if not s.icon_url:
                skipped += 1
                continue

            fname = safe_filename(s.name) + ".png"
            dest = self.icon_dir / fname
            color = self.db.get(s.name, "Color", "Yellow")
            color_dest = self.icon_dir / color / fname

            if dest.exists() or color_dest.exists():
                skipped += 1
                continue

            try:
                resp = requests.get(s.icon_url, timeout=15)
                resp.raise_for_status()
                dest.write_bytes(resp.content)
                downloaded += 1
            except Exception:
                skipped += 1

            if (i + 1) % 5 == 0:
                self.download_progress.emit(
                    f"Icon Download: {downloaded}/{total} ({skipped} skipped)"
                )

        self.download_progress.emit(
            f"Icon Download: Complete ({downloaded} downloaded, {skipped} skipped)"
        )

    def _detect_colors(self):
        self.download_progress.emit("Color Detection: Starting...")
        total = len(self.strategems)
        for i, s in enumerate(self.strategems):
            fname = safe_filename(s.name) + ".png"
            fpath = self.icon_dir / fname
            if not fpath.exists():
                continue
            color = detect_icon_color(str(fpath))
            s.color = color
            self.db.set_strat(s.name, "Color", color)
            if (i + 1) % 10 == 0:
                self.download_progress.emit(f"Color Detection: {i + 1}/{total}")
        self.download_progress.emit(f"Color Detection: Complete ({total} icons)")

    def _organize_icons(self):
        self.download_progress.emit("Organizing icons by color...")
        for color in ("Yellow", "Red", "Green", "Blue"):
            (self.icon_dir / color).mkdir(exist_ok=True)

        organized = 0
        for s in self.strategems:
            fname = safe_filename(s.name) + ".png"
            src = self.icon_dir / fname
            if not src.exists():
                continue
            color = self.db.get(s.name, "Color", "Yellow")
            dst = self.icon_dir / color / fname
            if not dst.exists():
                shutil.copy2(str(src), str(dst))
            src.unlink(missing_ok=True)
            organized += 1
        self.download_progress.emit(f"Organizing: Complete ({organized})")

    def _all_icons_organized(self) -> bool:
        for color in ("Yellow", "Red", "Green", "Blue"):
            if not (self.icon_dir / color).is_dir():
                return False
        for s in self.strategems:
            fname = safe_filename(s.name) + ".png"
            color = self.db.get(s.name, "Color", "Yellow")
            if not (self.icon_dir / color / fname).exists():
                return False
        return True

    def _check_missing_icons(self):
        self.download_progress.emit("Icon Check: Verifying...")
        if not self.strategems:
            self.strategems = self.db.load_strategems()

        for color in ("Yellow", "Red", "Green", "Blue"):
            (self.icon_dir / color).mkdir(parents=True, exist_ok=True)

        missing = 0
        for s in self.strategems:
            fname = safe_filename(s.name) + ".png"
            color = self.db.get(s.name, "Color", "Yellow")
            if not (self.icon_dir / color / fname).exists():
                missing += 1

        if missing == 0:
            self.download_progress.emit("Icon Check: Complete (all present)")
        else:
            self.download_progress.emit(f"Icon Check: {missing} icons missing")


# ─── Hotkey manager ─────────────────────────────────────────────────────────

class HotkeyManager:
    """Listens for Ctrl+Numpad keys and executes strategem codes.

    On Linux/Wayland: uses evdev to grab ALL keyboard devices exclusively,
    intercepts Ctrl+Numpad combos, and re-emits everything else via uinput.
    On Windows: uses pynput.
    """

    UINPUT_NAME = "NumpadStrategems-vkbd"

    def __init__(self, db: StrategemDB, get_settings_fn):
        self.db = db
        self.get_settings = get_settings_fn  # returns (arrow_keys: bool, delay_ms: int, release_ctrl: bool)
        self.ctrl_pressed = False
        self._executing = False
        self._running = False

        # evdev state (Linux) – now supports multiple grabbed devices
        self._ev_devices: list = []   # list of grabbed InputDevice
        self._ev_uinput = None
        self._ev_lock = threading.Lock()
        self._ev_thread = None
        self._ev_selector = None
        self._ev_ctrl_down = set()

        # pynput state (Windows)
        self._pynput_listener = None
        self._pynput_controller = None
        self._pynput_ctrl_down = set()

    def start(self):
        self._running = True
        import atexit
        atexit.register(self.stop)

        if platform.system() == "Linux" and HAS_EVDEV:
            if self._start_evdev():
                return
            print("evdev backend failed, falling back to pynput...")

        if HAS_PYNPUT:
            self._start_pynput()
        else:
            print("WARNING: No hotkey backend available – global hotkeys disabled")

    def stop(self):
        self._running = False
        self._stop_evdev()
        self._stop_pynput()

    # ─── evdev backend (Linux / Wayland) ────────────────────────────────

    def _start_evdev(self) -> bool:
        try:
            # Collect ALL keyboard-like devices (skip our own virtual keyboard)
            candidates = []
            for path in evdev.list_devices():
                dev = evdev.InputDevice(path)
                if dev.name == self.UINPUT_NAME:
                    dev.close()
                    continue
                caps = dev.capabilities(verbose=False)
                key_caps = set(caps.get(ec.EV_KEY, []))
                # Accept any device that has keyboard keys we care about
                has_numpad = bool(key_caps & set(_EV_NUMPAD_MAP.keys()))
                has_ctrl = bool(key_caps & _EV_CTRL_CODES)
                has_wasd = bool(key_caps & set(_EV_WASD_KEYS.values()))
                if has_numpad or has_ctrl or has_wasd:
                    candidates.append(dev)
                else:
                    dev.close()

            if not candidates:
                print("No keyboard/input devices found")
                return False

            # Create virtual keyboard that merges capabilities of all devices
            self._ev_uinput = evdev.UInput.from_device(
                *candidates, name=self.UINPUT_NAME
            )

            # Grab ALL candidate devices exclusively
            for dev in candidates:
                try:
                    dev.grab()
                    self._ev_devices.append(dev)
                    print(f"evdev: grabbed '{dev.name}' ({dev.path})")
                except Exception as e:
                    print(f"evdev: failed to grab '{dev.name}': {e}")
                    dev.close()

            if not self._ev_devices:
                print("Failed to grab any devices")
                if self._ev_uinput:
                    self._ev_uinput.close()
                    self._ev_uinput = None
                return False

            # Set up selector to poll all devices
            self._ev_selector = selectors.DefaultSelector()
            for dev in self._ev_devices:
                self._ev_selector.register(dev, selectors.EVENT_READ)

            self._ev_thread = threading.Thread(target=self._evdev_loop, daemon=True)
            self._ev_thread.start()
            return True

        except PermissionError:
            print("Permission denied accessing input devices.")
            print("The application needs elevated privileges to capture global hotkeys on Linux.")
            print("\nRestart the application and grant permission when prompted,")
            print("OR run with: pkexec python NumpadStrategems.py")
            return False
        except Exception as e:
            print(f"evdev init error: {e}")
            return False

    def _evdev_loop(self):
        """Read events from ALL grabbed devices and forward non-intercepted ones."""
        try:
            while self._running:
                # Block up to 0.5s waiting for events from any device
                events = self._ev_selector.select(timeout=0.5)
                for key, _mask in events:
                    device = key.fileobj
                    try:
                        for event in device.read():
                            if not self._running:
                                return
                            self._process_event(event)
                    except BlockingIOError:
                        continue

        except OSError:
            pass  # device closed during shutdown
        except Exception as e:
            print(f"evdev loop error: {e}")

    def _process_event(self, event):
        """Handle a single input event: intercept Ctrl+Numpad, forward everything else."""
        consumed = False

        if event.type == ec.EV_KEY:
            # Track Ctrl state
            if event.code in _EV_CTRL_CODES:
                if event.value != 0:
                    self._ev_ctrl_down.add(event.code)
                else:
                    self._ev_ctrl_down.discard(event.code)
                self.ctrl_pressed = bool(self._ev_ctrl_down)

            # Intercept ALL Ctrl+Numpad events (down, repeat, release)
            elif self.ctrl_pressed and event.code in _EV_NUMPAD_MAP:
                if event.value == 1:  # key down → trigger strategem
                    button_id = _EV_NUMPAD_MAP[event.code]
                    self._trigger(button_id)
                consumed = True  # swallow down, repeat, and release

        # Forward everything we didn't consume (including SYN, LED, etc.)
        if not consumed:
            with self._ev_lock:
                self._ev_uinput.write_event(event)

    def _stop_evdev(self):
        # Close selector
        if self._ev_selector:
            try:
                self._ev_selector.close()
            except Exception:
                pass
            self._ev_selector = None
        # Ungrab and close all grabbed devices
        for dev in self._ev_devices:
            try:
                dev.ungrab()
            except Exception:
                pass
            try:
                dev.close()
            except Exception:
                pass
        self._ev_devices.clear()
        # Close virtual keyboard
        if self._ev_uinput:
            try:
                self._ev_uinput.close()
            except Exception:
                pass
            self._ev_uinput = None

    # ─── pynput backend (Windows / fallback) ────────────────────────────

    def _start_pynput(self):
        self._pynput_controller = KeyboardController()
        self._pynput_listener = pynput_keyboard.Listener(
            on_press=self._pynput_on_press,
            on_release=self._pynput_on_release,
        )
        self._pynput_listener.daemon = True
        self._pynput_listener.start()

    def _stop_pynput(self):
        if self._pynput_listener:
            self._pynput_listener.stop()
            self._pynput_listener = None

    def _pynput_on_press(self, key):
        if key in (PynputKey.ctrl_l, PynputKey.ctrl_r):
            self.ctrl_pressed = True
            self._pynput_ctrl_down.add(key)
            return
        if not self.ctrl_pressed:
            return
        vk = getattr(key, "vk", None)
        if vk is None:
            return
        button_id = _NUMPAD_VK_MAP.get(vk)
        if button_id:
            self._trigger(button_id)

    def _pynput_on_release(self, key):
        if key in (PynputKey.ctrl_l, PynputKey.ctrl_r):
            self._pynput_ctrl_down.discard(key)
            self.ctrl_pressed = bool(self._pynput_ctrl_down)

    def _release_ctrl_modifiers(self):
        if self._ev_uinput and self._ev_ctrl_down:
            with self._ev_lock:
                for code in list(self._ev_ctrl_down):
                    self._ev_uinput.write(ec.EV_KEY, code, 0)
                self._ev_uinput.syn()
            self._ev_ctrl_down.clear()
            self.ctrl_pressed = False
        elif self._pynput_controller and self._pynput_ctrl_down:
            for key in list(self._pynput_ctrl_down):
                try:
                    self._pynput_controller.release(key)
                except Exception:
                    pass
            self._pynput_ctrl_down.clear()
            self.ctrl_pressed = False

    # ─── Shared trigger / execute logic ─────────────────────────────────

    def _trigger(self, button_key: str):
        if self._executing:
            return
        name = self.db.get_assignment(button_key)
        if not name or name == "__None__":
            return
        code = self.db.get(name, "Code")
        if not code:
            return
        self._executing = True
        t = threading.Thread(target=self._execute, args=(code,), daemon=True)
        t.start()

    def _execute(self, code: str):
        release_ctrl = False  # Default in case of early exception
        try:
            arrow_keys, delay_ms, release_ctrl = self.get_settings()
            delay = delay_ms / 1000.0

            if release_ctrl:
                self._release_ctrl_modifiers()

            if self._ev_uinput:
                # ── evdev output ──
                key_map = _EV_ARROW_KEYS if arrow_keys else _EV_WASD_KEYS
                for ch in code:
                    if not self.ctrl_pressed and not release_ctrl:
                        return
                    keycode = key_map.get(ch)
                    if keycode is None:
                        continue
                    with self._ev_lock:
                        self._ev_uinput.write(ec.EV_KEY, keycode, 1)
                        self._ev_uinput.syn()
                    time.sleep(delay)
                    with self._ev_lock:
                        self._ev_uinput.write(ec.EV_KEY, keycode, 0)
                        self._ev_uinput.syn()
                    time.sleep(delay)

            elif self._pynput_controller:
                # ── pynput output ──
                key_map = _ARROW_KEYS if arrow_keys else _WASD_KEYS
                for ch in code:
                    if not self.ctrl_pressed and not release_ctrl:
                        return
                    k = key_map.get(ch)
                    if k is None:
                        continue
                    self._pynput_controller.press(k)
                    time.sleep(delay)
                    self._pynput_controller.release(k)
                    time.sleep(delay)
        finally:
            self._executing = False


# ─── Custom Qt widgets ──────────────────────────────────────────────────────

class ClickableLabel(QLabel):
    """QLabel that emits signals on click/hover."""
    clicked = pyqtSignal()
    right_clicked = pyqtSignal()
    entered = pyqtSignal()
    left = pyqtSignal()

    def mousePressEvent(self, ev):
        if ev.button() == Qt.MouseButton.LeftButton:
            self.clicked.emit()
        elif ev.button() == Qt.MouseButton.RightButton:
            self.right_clicked.emit()
        super().mousePressEvent(ev)

    def enterEvent(self, ev):
        self.entered.emit()
        super().enterEvent(ev)

    def leaveEvent(self, ev):
        self.left.emit()
        super().leaveEvent(ev)


# ─── Status window ──────────────────────────────────────────────────────────

class StatusWindow(QDialog):
    dismissed = pyqtSignal()

    def __init__(self, settings: Settings, parent=None):
        super().__init__(parent)
        self.settings = settings
        self.setWindowTitle("Parsing Strategems")
        self.setWindowFlags(self.windowFlags() | Qt.WindowType.WindowStaysOnTopHint)
        self.setMinimumWidth(360)

        layout = QVBoxLayout(self)
        self.html_label = QLabel("HTML Download: Checking...")
        self.ini_label = QLabel("DB Generation: Waiting...")
        self.icon_label = QLabel("Placeholder Generation: Waiting...")
        self.dl_label = QLabel("Icon Download: Waiting...")
        layout.addWidget(self.html_label)
        layout.addWidget(self.ini_label)
        layout.addWidget(self.icon_label)
        layout.addWidget(self.dl_label)

        row = QHBoxLayout()
        self.auto_close_cb = QCheckBox("Auto-close when complete")
        self.auto_close_cb.setChecked(settings.getbool("Settings", "AutoClose", True))
        self.auto_close_cb.toggled.connect(self._on_auto_close_toggled)
        row.addWidget(self.auto_close_cb)
        self.dismiss_btn = QPushButton("Dismiss")
        self.dismiss_btn.clicked.connect(self._on_dismiss)
        row.addWidget(self.dismiss_btn)
        layout.addLayout(row)

        # Restore position
        x = settings.get("GUI", "StatusX")
        y = settings.get("GUI", "StatusY")
        if x and y:
            self.move(int(x), int(y))

        self._auto_close_timer: Optional[QTimer] = None
        self._already_dismissed = False
        self._init_complete = False

    def _on_auto_close_toggled(self, checked):
        self.settings.set("Settings", "AutoClose", int(checked))
        if not checked:
            # Unchecked: cancel any running timer
            self._stop_timer()
        else:
            # Re-checked: start timer if init already finished
            if self._init_complete:
                self.start_auto_close()

    def _on_dismiss(self):
        if self._already_dismissed:
            return
        self._already_dismissed = True
        self._stop_timer()
        self._save_pos()
        self.dismissed.emit()
        self.close()

    def closeEvent(self, ev):
        if not self._already_dismissed:
            self._already_dismissed = True
            self._stop_timer()
            self._save_pos()
            self.dismissed.emit()
        super().closeEvent(ev)

    def _save_pos(self):
        self.settings.set("GUI", "StatusX", self.x())
        self.settings.set("GUI", "StatusY", self.y())

    def start_auto_close(self):
        self._init_complete = True
        if self.auto_close_cb.isChecked():
            self._stop_timer()  # Clear any existing timer first
            self._auto_close_timer = QTimer(self)
            self._auto_close_timer.setSingleShot(True)
            self._auto_close_timer.timeout.connect(self._on_dismiss)
            self._auto_close_timer.start(3000)

    def _stop_timer(self):
        if self._auto_close_timer:
            self._auto_close_timer.stop()
            self._auto_close_timer = None

    def moveEvent(self, ev):
        self._save_pos()
        super().moveEvent(ev)


# ─── Main window ────────────────────────────────────────────────────────────

class MainWindow(QMainWindow):
    def __init__(self, data_dir: Path, settings: Settings, db: StrategemDB,
                 hotkey_mgr: HotkeyManager, parent=None):
        super().__init__(parent)
        self.data_dir = data_dir
        self.settings = settings
        self.db = db
        self.hotkey_mgr = hotkey_mgr
        self.icon_dir = data_dir / "icons"

        self.selected_strategem: str = ""
        self.selected_numpad_key: str = ""
        self.strat_buttons: Dict[str, ClickableLabel] = {}
        self.numpad_buttons: Dict[str, ClickableLabel] = {}
        self.low_delay_warning_shown = False
        self.secret_buffer = ""

        self.setWindowTitle("Stratagem Numpad")
        self.setStyleSheet(f"background-color: {DARK_BG}; color: white;")

        # Try to set window icon (use PNG on Linux for Wayland, ICO on Windows)
        icon_file = "Resupply.png" if platform.system() == "Linux" else "Resupply.ico"
        ico = Path(__file__).parent / icon_file
        if ico.exists():
            self.setWindowIcon(QIcon(str(ico)))

        self._build_ui()
        self._load_assignments()
        self.hotkey_mgr.start()

        # Restore position
        x = settings.get("GUI", "NumpadX")
        y = settings.get("GUI", "NumpadY")
        if x and y:
            self.move(int(x), int(y))

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)
        main_layout.setContentsMargins(5, 5, 5, 5)
        main_layout.setSpacing(10)

        # ── Left: strategem grid (no scroll, window sizes to fit) ──
        grid_widget = QWidget()
        self.strat_grid = QGridLayout(grid_widget)
        self.strat_grid.setSpacing(ICON_SPACING)
        self.strat_grid.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(grid_widget, 0)

        # ── Right: numpad + controls ──
        right = QVBoxLayout()
        right.setSpacing(5)
        main_layout.addLayout(right, 0)

        # Numpad grid
        numpad_widget = QWidget()
        numpad_grid = QGridLayout(numpad_widget)
        numpad_grid.setSpacing(5)
        numpad_grid.setContentsMargins(0, 0, 0, 0)

        # Create numpad buttons
        btn_defs = [
            # (key, row, col, rowspan, colspan, width, height)
            ("NumLock", 0, 0, 1, 1, 50, 50),
            ("/",       0, 1, 1, 1, 50, 50),
            ("*",       0, 2, 1, 1, 50, 50),
            ("-",       0, 3, 1, 1, 50, 50),
            ("7",       1, 0, 1, 1, 50, 50),
            ("8",       1, 1, 1, 1, 50, 50),
            ("9",       1, 2, 1, 1, 50, 50),
            ("+",       1, 3, 2, 1, 50, 105),
            ("4",       2, 0, 1, 1, 50, 50),
            ("5",       2, 1, 1, 1, 50, 50),
            ("6",       2, 2, 1, 1, 50, 50),
            ("1",       3, 0, 1, 1, 50, 50),
            ("2",       3, 1, 1, 1, 50, 50),
            ("3",       3, 2, 1, 1, 50, 50),
            ("Enter",   3, 3, 2, 1, 50, 105),
            ("0",       4, 0, 1, 2, 105, 50),
            (".",       4, 2, 1, 1, 50, 50),
        ]

        display_labels = {
            "NumLock": "NL", "/": "/", "*": "*", "-": "-",
            "7": "7", "8": "8", "9": "9", "+": "+",
            "4": "4", "5": "5", "6": "6",
            "1": "1", "2": "2", "3": "3", "Enter": "En",
            "0": "0", ".": ".",
        }

        for key, r, c, rs, cs, w, h in btn_defs:
            btn = ClickableLabel()
            btn.setFixedSize(w, h)
            btn.setAlignment(Qt.AlignmentFlag.AlignCenter)
            btn.setText(display_labels.get(key, key))
            btn.setFont(QFont("Segoe UI", 12, QFont.Weight.Bold))
            btn.setStyleSheet(
                "border: 1px solid #555; color: white; background-color: #2a2a2a;"
            )
            btn.clicked.connect(lambda k=key: self._numpad_clicked(k))
            btn.right_clicked.connect(lambda k=key: self._numpad_right_clicked(k))
            btn.entered.connect(lambda k=key: self._show_numpad_info(k))
            btn.left.connect(self._clear_info)
            numpad_grid.addWidget(btn, r, c, rs, cs)
            self.numpad_buttons[key] = btn

        right.addWidget(numpad_widget)

        # ── Delay control ──
        delay_row = QHBoxLayout()
        lbl = QLabel("Delay:")
        lbl.setFont(QFont("Segoe UI", 10))
        delay_row.addWidget(lbl)

        self.delay_display = QLabel(str(self.settings.getint("Settings", "KeyDelayMS", 67)))
        self.delay_display.setFont(QFont("Segoe UI", 10, QFont.Weight.Bold))
        self.delay_display.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.delay_display.setMinimumWidth(40)
        delay_row.addWidget(self.delay_display)

        ms_lbl = QLabel("ms")
        ms_lbl.setFont(QFont("Segoe UI", 10))
        delay_row.addWidget(ms_lbl)

        up_btn = QPushButton("▲")
        up_btn.setFixedSize(28, 24)
        up_btn.setStyleSheet("color: white; background-color: #333; border: 1px solid #555;")
        up_btn.clicked.connect(self._delay_up)
        delay_row.addWidget(up_btn)

        dn_btn = QPushButton("▼")
        dn_btn.setFixedSize(28, 24)
        dn_btn.setStyleSheet("color: white; background-color: #333; border: 1px solid #555;")
        dn_btn.clicked.connect(self._delay_down)
        delay_row.addWidget(dn_btn)

        delay_row.addStretch()
        right.addLayout(delay_row)

        # ── Checkboxes ──
        self.always_on_top_cb = QCheckBox("Always on Top")
        self.always_on_top_cb.setFont(QFont("Segoe UI", 10))
        self.always_on_top_cb.setStyleSheet("color: white;")
        self.always_on_top_cb.setChecked(self.settings.getbool("Numpad", "AlwaysOnTop"))
        self.always_on_top_cb.toggled.connect(self._toggle_always_on_top)
        right.addWidget(self.always_on_top_cb)
        if self.always_on_top_cb.isChecked():
            self.setWindowFlags(self.windowFlags() | Qt.WindowType.WindowStaysOnTopHint)

        self.arrow_keys_cb = QCheckBox("Arrow Keys")
        self.arrow_keys_cb.setFont(QFont("Segoe UI", 10))
        self.arrow_keys_cb.setStyleSheet("color: white;")
        self.arrow_keys_cb.setChecked(self.settings.getbool("Numpad", "ArrowKeys", True))
        self.arrow_keys_cb.toggled.connect(
            lambda v: self.settings.set("Numpad", "ArrowKeys", int(v))
        )
        right.addWidget(self.arrow_keys_cb)

        self.release_ctrl_cb = QCheckBox("Release Ctrl Before Input")
        self.release_ctrl_cb.setFont(QFont("Segoe UI", 10))
        self.release_ctrl_cb.setStyleSheet("color: white;")
        self.release_ctrl_cb.setChecked(self.settings.getbool("Numpad", "ReleaseCtrl", False))
        self.release_ctrl_cb.toggled.connect(
            lambda v: self.settings.set("Numpad", "ReleaseCtrl", int(v))
        )
        right.addWidget(self.release_ctrl_cb)

        # ── Hover info display ──
        right.addSpacing(10)
        self.info_name = QLabel("")
        self.info_name.setFont(QFont("Segoe UI", 14, QFont.Weight.Bold))
        self.info_name.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.info_name.setWordWrap(True)
        self.info_name.setMinimumWidth(220)
        right.addWidget(self.info_name)

        self.info_warbond = QLabel("")
        self.info_warbond.setFont(QFont("Segoe UI", 10))
        self.info_warbond.setAlignment(Qt.AlignmentFlag.AlignCenter)
        right.addWidget(self.info_warbond)

        self.info_assignment = QLabel("")
        self.info_assignment.setFont(QFont("Segoe UI", 10))
        self.info_assignment.setAlignment(Qt.AlignmentFlag.AlignCenter)
        right.addWidget(self.info_assignment)

        # Arrow code display
        self.arrow_container = QHBoxLayout()
        self.arrow_container.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.arrow_labels: List[QLabel] = []
        for _ in range(8):
            al = QLabel()
            al.setFixedSize(22, 22)
            al.hide()
            self.arrow_container.addWidget(al)
            self.arrow_labels.append(al)
        right.addLayout(self.arrow_container)

        right.addStretch()

        # ── Populate strategem grid ──
        self._populate_grid()

        # ── Size the window to fit all content ──
        self.adjustSize()

    def _populate_grid(self):
        strategems = self.db.load_strategems()
        strategems = self._sort_by_color(strategems)

        # Group by color
        groups: Dict[str, List[Strategem]] = {
            "Yellow": [], "Red": [], "Green": [], "Blue": []
        }
        for s in strategems:
            groups.setdefault(s.color, []).append(s)

        # Sort sub-groups
        groups["Blue"] = self._sort_blue(groups.get("Blue", []))
        groups["Red"] = self._sort_red(groups.get("Red", []))
        groups["Green"] = self._sort_green(groups.get("Green", []))

        row = 0
        col = 0
        for color_name in ("Yellow", "Red", "Green", "Blue"):
            items = groups.get(color_name, [])
            if not items:
                continue
            # Start new row for each color group
            if col > 0:
                row += 1
                col = 0
            for s in items:
                btn = self._make_strat_button(s)
                self.strat_grid.addWidget(btn, row, col)
                self.strat_buttons[s.name] = btn
                col += 1
                if col >= ITEMS_PER_ROW:
                    col = 0
                    row += 1
            # If last row wasn't full, that's fine – next color starts new row

    def _make_strat_button(self, s: Strategem) -> ClickableLabel:
        btn = ClickableLabel()
        btn.setFixedSize(ICON_SIZE, ICON_SIZE)
        btn.setAlignment(Qt.AlignmentFlag.AlignCenter)

        icon_path = self.icon_dir / s.color / (safe_filename(s.name) + ".png")
        if icon_path.exists():
            pm = QPixmap(str(icon_path)).scaled(
                ICON_SIZE, ICON_SIZE,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
            btn.setPixmap(pm)
        else:
            btn.setText("?")
            btn.setFont(QFont("Segoe UI", 14))

        btn.setStyleSheet("border: 1px solid #333;")
        btn.clicked.connect(lambda name=s.name: self._strat_clicked(name))
        btn.entered.connect(lambda name=s.name: self._show_strat_info(name))
        btn.left.connect(self._clear_info)
        return btn

    # ── Sorting helpers ──

    def _sort_by_color(self, strats: List[Strategem]) -> List[Strategem]:
        prio = {"Yellow": 0, "Red": 1, "Green": 2, "Blue": 3}
        return sorted(strats, key=lambda s: prio.get(s.color, 4))

    def _sort_blue(self, items: List[Strategem]) -> List[Strategem]:
        vehicles, top, prio, other = [], [], [], []
        for s in items:
            n = s.name
            if any(k in n for k in ("Exosuit", "Vehicule", "Vehicle")):
                vehicles.append(s)
            elif any(k in n for k in ("Hover", "Jump", "Warp")):
                top.append(s)
            elif any(k in n for k in ("Guard Dog", "Pack", "Shield", "Hellbomb")):
                prio.append(s)
            else:
                other.append(s)
        return vehicles + top + prio + other

    def _sort_red(self, items: List[Strategem]) -> List[Strategem]:
        rearm, eagles, regular = [], [], []
        for s in items:
            if "Eagle Rearm" in s.name:
                rearm.append(s)
            elif "Eagle" in s.name:
                eagles.append(s)
            else:
                regular.append(s)
        return rearm + eagles + regular

    def _sort_green(self, items: List[Strategem]) -> List[Strategem]:
        regular, sentries = [], []
        for s in items:
            if "Sentry" in s.name or "Emplacement" in s.name:
                sentries.append(s)
            else:
                regular.append(s)
        return regular + sentries

    # ── Click handlers ──

    def _strat_clicked(self, name: str):
        if self.selected_numpad_key:
            # Numpad already selected → assign
            self._assign(name, self.selected_numpad_key)
            self._deselect_all()
        elif self.selected_strategem == name:
            # Clicking same strategem deselects
            self._deselect_all()
        else:
            self._deselect_all()
            self.selected_strategem = name
            if name in self.strat_buttons:
                self.strat_buttons[name].setStyleSheet(
                    "border: 2px solid #FFD700;"
                )

    def _numpad_clicked(self, key: str):
        if self.selected_strategem:
            # Strategem already selected → assign
            self._assign(self.selected_strategem, key)
            self._deselect_all()
        elif self.selected_numpad_key == key:
            self._deselect_all()
        else:
            self._deselect_all()
            self.selected_numpad_key = key
            if key in self.numpad_buttons:
                self.numpad_buttons[key].setStyleSheet(
                    "border: 2px solid #FFD700; color: white; background-color: #2a2a2a;"
                )

    def _numpad_right_clicked(self, key: str):
        self.db.set_assignment(key, "__None__")
        self._update_numpad_button(key, "__None__")
        self._deselect_all()

    def _deselect_all(self):
        if self.selected_strategem and self.selected_strategem in self.strat_buttons:
            self.strat_buttons[self.selected_strategem].setStyleSheet(
                "border: 1px solid #333;"
            )
        if self.selected_numpad_key and self.selected_numpad_key in self.numpad_buttons:
            self.numpad_buttons[self.selected_numpad_key].setStyleSheet(
                "border: 1px solid #555; color: white; background-color: #2a2a2a;"
            )
        self.selected_strategem = ""
        self.selected_numpad_key = ""

    def _assign(self, strategem_name: str, button_key: str):
        self.db.set_assignment(button_key, strategem_name)
        self._update_numpad_button(button_key, strategem_name)

    _NUMPAD_DISPLAY = {
        "NumLock": "NL", "/": "/", "*": "*", "-": "-",
        "7": "7", "8": "8", "9": "9", "+": "+",
        "4": "4", "5": "5", "6": "6",
        "1": "1", "2": "2", "3": "3", "Enter": "En",
        "0": "0", ".": ".",
    }

    def _stamp_label_on_pixmap(self, pm: QPixmap, key: str, btn_w: int, btn_h: int) -> QPixmap:
        """Create a button-sized pixmap with the icon centered and label overlaid."""
        # Create full button-size pixmap with dark background
        result = QPixmap(btn_w, btn_h)
        result.fill(QColor(DARK_BG))

        painter = QPainter(result)
        # Center the icon pixmap on the full-size result
        ox = (btn_w - pm.width()) // 2
        oy = (btn_h - pm.height()) // 2
        painter.drawPixmap(ox, oy, pm)

        # Draw text label with dark outline for visibility
        label = self._NUMPAD_DISPLAY.get(key, key)
        font = QFont("Segoe UI", 12, QFont.Weight.Bold)
        painter.setFont(font)

        rect = result.rect()
        # Draw dark outline by drawing text offset in each direction
        painter.setPen(QColor(0, 0, 0, 220))
        for dx, dy in [(-1,-1), (-1,1), (1,-1), (1,1), (-2,0), (2,0), (0,-2), (0,2)]:
            painter.drawText(rect.adjusted(dx, dy, dx, dy), Qt.AlignmentFlag.AlignCenter, label)

        # Draw white text on top
        painter.setPen(QColor(255, 255, 255, 240))
        painter.drawText(rect, Qt.AlignmentFlag.AlignCenter, label)
        painter.end()
        return result

    def _update_numpad_button(self, key: str, strategem_name: str):
        btn = self.numpad_buttons.get(key)
        if not btn:
            return

        # Determine button dimensions
        w, h = btn.width(), btn.height()
        label = self._NUMPAD_DISPLAY.get(key, key)

        if strategem_name and strategem_name != "__None__":
            color = self.db.get(strategem_name, "Color", "Yellow")
            icon_path = self.icon_dir / color / (safe_filename(strategem_name) + ".png")
            if icon_path.exists():
                if w != h:
                    # Non-square: create scaled version
                    scaled_dir = self.icon_dir / "scaled"
                    scaled_dir.mkdir(exist_ok=True)
                    scaled_path = scaled_dir / f"{safe_filename(strategem_name)}_{w}x{h}.png"
                    if not scaled_path.exists():
                        scale_icon_to_button(str(icon_path), w, h, str(scaled_path))
                    if scaled_path.exists():
                        pm = QPixmap(str(scaled_path))
                    else:
                        pm = QPixmap(str(icon_path)).scaled(
                            w, h, Qt.AspectRatioMode.KeepAspectRatio,
                            Qt.TransformationMode.SmoothTransformation)
                else:
                    pm = QPixmap(str(icon_path)).scaled(
                        w, h, Qt.AspectRatioMode.KeepAspectRatio,
                        Qt.TransformationMode.SmoothTransformation)
                # Overlay the numpad label on the icon
                pm = self._stamp_label_on_pixmap(pm, key, w, h)
                btn.setPixmap(pm)
                btn.setText("")
            else:
                btn.setPixmap(QPixmap())
                btn.setText("?")
        else:
            # Unassigned: clear pixmap and restore the text label
            btn.setPixmap(QPixmap())
            btn.setText(label)

        btn.setStyleSheet(
            "border: 1px solid #555; color: white; background-color: #2a2a2a;"
        )

    # ── Hover info ──

    def _show_strat_info(self, name: str):
        self.info_name.setText(name)
        warbond = self.db.get(name, "Warbond", "General")
        self.info_warbond.setText(warbond if warbond != "General" else "")
        assignment = self.db.find_assignment_for(name)
        self.info_assignment.setText(f"Numpad {assignment}" if assignment else "")
        code = self.db.get(name, "Code")
        self._show_arrows(code)

    def _show_numpad_info(self, key: str):
        name = self.db.get_assignment(key)
        if name and name != "__None__":
            self._show_strat_info(name)
            self.info_assignment.setText(f"Numpad {key}")
        else:
            self.info_name.setText(f"Numpad {key}")
            self.info_warbond.setText("")
            self.info_assignment.setText("Not assigned")
            self._clear_arrows()

    def _clear_info(self):
        self.info_name.setText("")
        self.info_warbond.setText("")
        self.info_assignment.setText("")
        self._clear_arrows()

    def _show_arrows(self, code: str):
        arrow_dir = self.icon_dir / "arrows"
        arrow_map = {"U": "up.png", "D": "down.png", "L": "left.png", "R": "right.png"}
        for i, lbl in enumerate(self.arrow_labels):
            if i < len(code):
                ch = code[i]
                fname = arrow_map.get(ch)
                if fname:
                    ap = arrow_dir / fname
                    if ap.exists():
                        pm = QPixmap(str(ap)).scaled(
                            20, 20,
                            Qt.AspectRatioMode.KeepAspectRatio,
                            Qt.TransformationMode.SmoothTransformation)
                        lbl.setPixmap(pm)
                        lbl.show()
                        continue
                lbl.hide()
            else:
                lbl.setPixmap(QPixmap())
                lbl.hide()

    def _clear_arrows(self):
        for lbl in self.arrow_labels:
            lbl.setPixmap(QPixmap())
            lbl.hide()

    # ── Delay control ──

    def _delay_up(self):
        val = int(self.delay_display.text()) + 1
        if val <= 999:
            self.delay_display.setText(str(val))

    def _delay_down(self):
        val = int(self.delay_display.text()) - 1
        if val >= 1:
            if val < 25 and int(self.delay_display.text()) >= 25 and not self.low_delay_warning_shown:
                self.low_delay_warning_shown = True
                QMessageBox.warning(
                    self, "Low Delay Warning",
                    "Delays below 25ms may cause reliability issues with longer strategems.\n"
                    "The longer the strategem code, the more delay is recommended.\n\n"
                    "You need about 6-7ms for each strategem input."
                )
            self.delay_display.setText(str(val))

    # ── Always on top ──

    def _toggle_always_on_top(self, checked):
        self.settings.set("Numpad", "AlwaysOnTop", int(checked))
        if checked:
            self.setWindowFlags(self.windowFlags() | Qt.WindowType.WindowStaysOnTopHint)
        else:
            self.setWindowFlags(self.windowFlags() & ~Qt.WindowType.WindowStaysOnTopHint)
        self.show()

    # ── Assignments persistence ──

    def _load_assignments(self):
        for key in self.numpad_buttons:
            name = self.db.get_assignment(key)
            if name:
                self._update_numpad_button(key, name)

    # ── Settings bridge for hotkey manager ──

    def get_hotkey_settings(self) -> Tuple[bool, int, bool]:
        return (self.arrow_keys_cb.isChecked(), int(self.delay_display.text()), self.release_ctrl_cb.isChecked())

    # ── Secret code ──

    def keyPressEvent(self, ev):
        ch = ev.text().lower()
        if ch in "sixevn":
            self.secret_buffer += ch
            if len(self.secret_buffer) > 9:
                self.secret_buffer = self.secret_buffer[-9:]
            if "sixseven" in self.secret_buffer:
                self.secret_buffer = ""
                self._reset_appdata()
            return
        super().keyPressEvent(ev)

    def _reset_appdata(self):
        try:
            shutil.rmtree(str(self.data_dir))
        except Exception:
            pass
        # Restart
        os.execv(sys.executable, [sys.executable] + sys.argv)

    # ── Save state on close ──

    def closeEvent(self, ev):
        self.settings.set("GUI", "NumpadX", self.x())
        self.settings.set("GUI", "NumpadY", self.y())
        self.settings.set("Settings", "KeyDelayMS", self.delay_display.text())
        self.hotkey_mgr.stop()
        super().closeEvent(ev)

    def moveEvent(self, ev):
        self.settings.set("GUI", "NumpadX", self.x())
        self.settings.set("GUI", "NumpadY", self.y())
        super().moveEvent(ev)


# ─── Application ────────────────────────────────────────────────────────────

class App:
    def __init__(self):
        self.qt_app = QApplication(sys.argv)
        self.qt_app.setStyle("Fusion")

        # Dark palette
        palette = QPalette()
        palette.setColor(QPalette.ColorRole.Window, QColor(DARK_BG))
        palette.setColor(QPalette.ColorRole.WindowText, QColor("white"))
        palette.setColor(QPalette.ColorRole.Base, QColor("#2a2a2a"))
        palette.setColor(QPalette.ColorRole.AlternateBase, QColor(DARK_BG))
        palette.setColor(QPalette.ColorRole.Text, QColor("white"))
        palette.setColor(QPalette.ColorRole.Button, QColor("#2a2a2a"))
        palette.setColor(QPalette.ColorRole.ButtonText, QColor("white"))
        palette.setColor(QPalette.ColorRole.Highlight, QColor("#FFD700"))
        palette.setColor(QPalette.ColorRole.HighlightedText, QColor("black"))
        self.qt_app.setPalette(palette)

        # Set window icon globally (use PNG on Linux for Wayland, ICO on Windows)
        icon_file = "Resupply.png" if platform.system() == "Linux" else "Resupply.ico"
        ico = Path(__file__).parent / icon_file
        if ico.exists():
            self.qt_app.setWindowIcon(QIcon(str(ico)))

        self.data_dir = get_data_dir()
        self.data_dir.mkdir(parents=True, exist_ok=True)

        self.settings = Settings(self.data_dir / f"{SCRIPT_NAME}.ini")
        self.db = StrategemDB(self.data_dir)

        self.status_win: Optional[StatusWindow] = None
        self.main_win: Optional[MainWindow] = None
        self.hotkey_mgr: Optional[HotkeyManager] = None

    def run(self):
        # Show status window
        self.status_win = StatusWindow(self.settings)
        self.status_win.dismissed.connect(self._on_status_dismissed)
        self.status_win.show()

        # Start init worker
        self.worker = InitWorker(self.data_dir, self.db)
        self.worker.html_progress.connect(self.status_win.html_label.setText)
        self.worker.ini_progress.connect(self.status_win.ini_label.setText)
        self.worker.icon_progress.connect(self.status_win.icon_label.setText)
        self.worker.download_progress.connect(self.status_win.dl_label.setText)
        self.worker.finished.connect(self._on_init_done)
        self.worker.start()

        return self.qt_app.exec()

    def _on_init_done(self, success: bool):
        self.db.reload()
        if success and self.status_win:
            self.status_win.start_auto_close()

    def _on_status_dismissed(self):
        self.status_win = None
        self._show_main()

    def _show_main(self):
        self.db.reload()
        self.hotkey_mgr = HotkeyManager(self.db, lambda: (False, 67, False))
        self.main_win = MainWindow(
            self.data_dir, self.settings, self.db, self.hotkey_mgr
        )
        # Wire up the settings bridge properly now that main_win exists
        self.hotkey_mgr.get_settings = self.main_win.get_hotkey_settings
        self.main_win.show()


# ─── Entry point ────────────────────────────────────────────────────────────

def get_binary_hash() -> str:
    """Get SHA256 hash of the current executable/script."""
    try:
        exe_path = os.path.abspath(sys.executable if getattr(sys, 'frozen', False) else __file__)
        sha256 = hashlib.sha256()
        with open(exe_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                sha256.update(chunk)
        return sha256.hexdigest()
    except Exception as e:
        print(f"Failed to calculate binary hash: {e}")
        return ""

def cleanup_old_polkit_rules():
    """Remove old NumpadStrategems PolicyKit rules with different hashes."""
    rules_dir = Path("/etc/polkit-1/rules.d")
    if not rules_dir.exists():
        return
    
    current_hash = get_binary_hash()
    if not current_hash:
        return
    
    try:
        for rule_file in rules_dir.glob("99-numpadstrategems-*.rules"):
            # Extract hash from filename
            match = re.search(r'99-numpadstrategems-([a-f0-9]{8})\.rules', rule_file.name)
            if match:
                file_hash_prefix = match.group(1)
                if not current_hash.startswith(file_hash_prefix):
                    # Old rule, remove it
                    try:
                        subprocess.run(['pkexec', 'rm', str(rule_file)], 
                                     check=False, capture_output=True)
                        print(f"Cleaned up old PolicyKit rule: {rule_file.name}")
                    except Exception as e:
                        print(f"Failed to remove old rule {rule_file.name}: {e}")
    except Exception as e:
        print(f"Failed to cleanup old PolicyKit rules: {e}")

def setup_passwordless_elevation():
    """Create a PolicyKit rule to allow this binary to run without password."""
    binary_hash = get_binary_hash()
    if not binary_hash:
        return False
    
    # Use first 8 chars of hash for filename
    hash_prefix = binary_hash[:8]
    rule_file = f"/etc/polkit-1/rules.d/99-numpadstrategems-{hash_prefix}.rules"
    
    # Check if rule already exists
    if os.path.exists(rule_file):
        return True
    
    rule_content = f'''/* Allow NumpadStrategems (hash: {binary_hash}) to run without password */
polkit.addRule(function(action, subject) {{
    if (action.id == "org.freedesktop.policykit.exec" &&
        subject.isInGroup("wheel") || subject.isInGroup("sudo")) {{
        
        // Get the command being executed
        var program = action.lookup("program");
        if (!program) return polkit.Result.NOT_HANDLED;
        
        // Calculate hash of the program
        try {{
            var hash = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, 
                       GLib.file_get_contents(program)[1], -1);
            
            // Allow if hash matches
            if (hash == "{binary_hash}") {{
                return polkit.Result.YES;
            }}
        }} catch(e) {{
            // Ignore errors
        }}
    }}
    return polkit.Result.NOT_HANDLED;
}});
'''
    
    # Create a temporary file with the rule
    import tempfile
    try:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.rules') as f:
            f.write(rule_content)
            temp_file = f.name
        
        # Use pkexec to copy it to the system directory
        result = subprocess.run(
            ['pkexec', 'sh', '-c', 
             f'mkdir -p /etc/polkit-1/rules.d && cp {temp_file} {rule_file} && chmod 644 {rule_file}'],
            capture_output=True, text=True
        )
        
        os.unlink(temp_file)
        
        if result.returncode == 0:
            print(f"PolicyKit rule created: {rule_file}")
            # Reload PolicyKit
            subprocess.run(['pkexec', 'systemctl', 'restart', 'polkit'], 
                         check=False, capture_output=True)
            return True
        else:
            print(f"Failed to create PolicyKit rule: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"Failed to setup passwordless elevation: {e}")
        return False

def ask_passwordless_setup():
    """Show dialog asking if user wants passwordless startup."""
    from PyQt6.QtWidgets import QMessageBox
    from PyQt6.QtCore import Qt
    
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Icon.Question)
    msg.setWindowTitle("Enable Passwordless Startup?")
    msg.setText("NumpadStrategems needs elevated privileges to capture global hotkeys on Linux.")
    msg.setInformativeText(
        "Would you like to enable passwordless startup?\n\n"
        "This will create a PolicyKit rule that identifies this application by its "
        "binary hash (not path), so it works even if you move the binary.\n\n"
        "You'll need to enter your password once to set this up."
    )
    msg.setStandardButtons(QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
    msg.setDefaultButton(QMessageBox.StandardButton.Yes)
    
    return msg.exec() == QMessageBox.StandardButton.Yes

def check_and_elevate_if_needed():
    """On Linux, check if we need elevated privileges for evdev and relaunch with pkexec if needed."""
    if platform.system() != "Linux" or not HAS_EVDEV:
        return  # Not Linux or evdev not available
    
    # Check if we're already running as root
    if os.geteuid() == 0:
        return  # Already elevated
    
    # Check if we have permission to access input devices
    try:
        # Try to open an input device to test permissions
        devices = evdev.list_devices()
        if not devices:
            return  # No devices to test
        
        # Try opening and grabbing a device
        test_dev = evdev.InputDevice(devices[0])
        try:
            test_dev.grab()
            test_dev.ungrab()
            test_dev.close()
            return  # We have permissions, no need to elevate
        except (OSError, PermissionError):
            test_dev.close()
            # Need elevation - relaunch with pkexec
            pass
    except (PermissionError, OSError):
        pass  # Need elevation
    
    # Check if pkexec is available
    if not shutil.which('pkexec'):
        # pkexec not available, app will show error later
        return
    
    # Check if this is the first elevation attempt (not a retry after setup)
    if '--skip-passwordless-prompt' not in sys.argv:
        # Initialize Qt for the dialog
        from PyQt6.QtWidgets import QApplication
        temp_app = QApplication.instance()
        if temp_app is None:
            temp_app = QApplication(sys.argv)
        
        # Ask if user wants passwordless setup
        if ask_passwordless_setup():
            # Clean up old rules first
            cleanup_old_polkit_rules()
            # Setup passwordless elevation
            if setup_passwordless_elevation():
                print("Passwordless elevation configured successfully!")
    
    # Relaunch with pkexec
    try:
        python_exe = sys.executable
        script_path = os.path.abspath(__file__)
        args = [python_exe, script_path, '--skip-passwordless-prompt'] + \
               [arg for arg in sys.argv[1:] if arg != '--skip-passwordless-prompt']
        
        # Use pkexec to relaunch with graphical password prompt
        os.execvp('pkexec', ['pkexec'] + args)
    except Exception as e:
        print(f"Failed to elevate privileges: {e}")
        # Continue anyway, will fall back to pynput or show error


def main():
    check_and_elevate_if_needed()
    app = App()
    sys.exit(app.run())


if __name__ == "__main__":
    main()
