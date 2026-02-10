#!/usr/bin/env python3
"""
Build script for creating standalone binaries using PyInstaller
Run this on the target platform (Windows or Linux)

Usage:
    pip install pyinstaller
    python build_binary.py
"""

import PyInstaller.__main__
import platform
import sys

def build_binary():
    system = platform.system()
    
    args = [
        'NumpadStrategems.py',
        '--onefile',  # Single executable
        '--windowed' if system == 'Windows' else '',  # No console on Windows
        '--name=NumpadStrategems',
        '--icon=Resupply.ico',  # Application icon
        '--hidden-import=PyQt6.QtCore',
        '--hidden-import=PyQt6.QtGui',
        '--hidden-import=PyQt6.QtWidgets',
        '--hidden-import=pynput',
        '--hidden-import=pynput.keyboard',
        '--hidden-import=pynput.mouse',
        '--collect-all=PyQt6',
    ]
    
    # Add Linux-specific imports
    if system == 'Linux':
        args.extend([
            '--hidden-import=evdev',
            '--hidden-import=Xlib',
        ])
    
    # Filter out empty strings
    args = [arg for arg in args if arg]
    
    print(f"Building for {system}...")
    print(f"Arguments: {args}")
    
    PyInstaller.__main__.run(args)
    print(f"\nBuild complete! Check the 'dist' folder for your binary.")

if __name__ == '__main__':
    build_binary()
