# -*- mode: python ; coding: utf-8 -*-

# Embed icon and desktop entry for Linux/Windows cross-platform support
import sys
import os

# Icon path for embedding in binary
icon_path = os.path.join(os.path.dirname(__file__), 'Resupply.ico')

# Data files to include (icon and desktop entry for Linux)
datas_list = [
    ('Resupply.png', '.'),  # Include PNG for run-time use
    ('NumpadStrategems.desktop', '.'),  # Include desktop entry for Linux
]

a = Analysis(
    ['NumpadStrategems.py'],
    pathex=[],
    binaries=[],
    datas=datas_list,
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='NumpadStrategems',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    # Use repository-provided icon if available (kept in project root)
    icon=['Resupply.ico'],
)
