#!/usr/bin/env python3
"""
Build script for creating standalone binaries using PyInstaller
Run this on the target platform (Windows or Linux)

Usage:
    pip install pyinstaller
    python build_binary.py
"""

import PyInstaller.__main__
import argparse
import os
import platform
import sys

def _get_version_string(cli_version: str | None) -> str:
    if cli_version:
        return cli_version.lstrip("v")
    ref_name = os.environ.get("GITHUB_REF_NAME", "")
    if ref_name:
        return ref_name.lstrip("v")
    return "dev"


def _platform_label(system: str) -> str:
    if system == "Windows":
        return "Windows"
    if system == "Linux":
        return "Linux"
    return system


def build_binary(version: str | None):
    system = platform.system()
    version_str = _get_version_string(version)
    platform_str = _platform_label(system)
    
    print(f"Building for {system}...")
    print(f"Using spec file: NumpadStrategems.spec")
    
    # Use the spec file for cleaner, more reliable builds
    PyInstaller.__main__.run(['NumpadStrategems.spec'])
    
    # Rename binary with version info
    ext = ".exe" if system == "Windows" else ""
    src_name = f"NumpadStrategems{ext}"
    dst_name = f"NumpadStrategems-{version_str}-{platform_str}{ext}"
    src_path = os.path.join("dist", src_name)
    dst_path = os.path.join("dist", dst_name)
    if os.path.exists(src_path):
        os.replace(src_path, dst_path)
        print(f"\nBuild complete! Binary: {dst_name}")
    else:
        print(f"\nERROR: Expected binary not found at {src_path}")

    # Match GitHub Actions naming: NumpadStrategems-<version>-<platform>[.exe]
    ext = ".exe" if system == "Windows" else ""
    src_name = f"NumpadStrategems{ext}"
    dst_name = f"NumpadStrategems-{version_str}-{platform_str}{ext}"
    src_path = os.path.join("dist", src_name)
    dst_path = os.path.join("dist", dst_name)
    if os.path.exists(src_path):
        os.replace(src_path, dst_path)

    print(f"\nBuild complete! Check the 'dist' folder for your binary:")
    print(f"  {dst_name}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Build NumpadStrategems binary")
    parser.add_argument(
        "--version",
        help="Version string for output name (e.g., 0.0.2). Defaults to tag or 'dev'.",
    )
    args = parser.parse_args()
    build_binary(args.version)
