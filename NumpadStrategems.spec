# -*- mode: python ; coding: utf-8 -*-

import sys
import platform

# Data files to include (platform-specific)
datas_list = [
    ('Resupply.png', '.'),  # Include PNG for run-time use on Linux/bundle directory
]

# Only include desktop file on Linux
if platform.system() == 'Linux':
    datas_list.append(('NumpadStrategems.desktop', '.'))

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
    icon='Resupply.ico',
)
