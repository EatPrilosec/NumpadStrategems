# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec file for NumpadStrategems
Allows more control over the build process

Usage:
    pyinstaller NumpadStrategems.spec
"""

import platform

block_cipher = None
system = platform.system()

a = Analysis(
    ['NumpadStrategems.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'PyQt6.QtCore',
        'PyQt6.QtGui', 
        'PyQt6.QtWidgets',
        'pynput',
        'pynput.keyboard',
        'pynput.mouse',
        'requests',
        'Pillow',
    ] + (['evdev'] if system == 'Linux' else []),
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='NumpadStrategems',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False if system == 'Windows' else True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='Resupply.ico',
)
