# Building Standalone Binaries for NumpadStrategems

This guide explains how to create portable, standalone binaries for Windows and Linux.

## Prerequisites

Install PyInstaller:
```bash
pip install pyinstaller
```

## Method 1: Using the Build Script (Easiest)

### On Linux:
```bash
python build_binary.py --version 0.0.2
```

### On Windows:
```cmd
python build_binary.py --version 0.0.2
```

The binary will be created in the `dist/` folder.

## Method 2: Using the Spec File (More Control)

### On Linux:
```bash
pyinstaller NumpadStrategems.spec
```

### On Windows:
```cmd
pyinstaller NumpadStrategems.spec
```

## Method 3: Direct PyInstaller Command

### For Linux:
```bash
pyinstaller --onefile \
    --name=NumpadStrategems \
    --add-data="Resupply.png:." \
    --hidden-import=PyQt6.QtCore \
    --hidden-import=PyQt6.QtGui \
    --hidden-import=PyQt6.QtWidgets \
    --hidden-import=pynput \
    --hidden-import=evdev \
    --collect-all=PyQt6 \
    NumpadStrategems.py
```

### For Windows:
```cmd
pyinstaller --onefile ^
    --windowed ^
    --name=NumpadStrategems ^
    --add-data="Resupply.png:." ^
    --hidden-import=PyQt6.QtCore ^
    --hidden-import=PyQt6.QtGui ^
    --hidden-import=PyQt6.QtWidgets ^
    --hidden-import=pynput ^
    --collect-all=PyQt6 ^
    NumpadStrategems.py
```

## Build Output

After building, you'll find:
- **dist/NumpadStrategems-<version>-Linux** (Linux)
- **dist/NumpadStrategems-<version>-Windows.exe** (Windows)
- This is your standalone portable binary!
- The `build/` folder contains temporary build files (can be deleted)
- The `.spec` file can be used for reproducible builds

## Testing the Binary

### Linux:
```bash
./dist/NumpadStrategems-0.0.2-Linux
```

### Windows:
```cmd
dist\NumpadStrategems-0.0.2-Windows.exe
```

## Important Notes

1. **Cross-compilation is NOT supported**: You must build on the target OS
   - Build Windows binaries on Windows
   - Build Linux binaries on Linux

2. **Application icon**: The binary uses `Resupply.ico` as its icon. Other strategem icons are downloaded dynamically at runtime.

3. **Binary size**: The binaries will be 40-80MB due to bundled Python interpreter and Qt libraries

4. **UPX compression** (optional): To reduce binary size, install UPX:
   - Linux: `sudo apt install upx` or `sudo pacman -S upx`
   - Windows: Download from https://upx.github.io/
   - PyInstaller will automatically use UPX if available

## CI/CD Automation

For automated builds, you can use GitHub Actions:

### Linux Build:
```yaml
- name: Build Linux Binary
  run: |
    pip install pyinstaller
    pyinstaller NumpadStrategems.spec
```

### Windows Build:
```yaml
- name: Build Windows Binary
  run: |
    pip install pyinstaller
    pyinstaller NumpadStrategems.spec
```

## Troubleshooting

### Missing modules error:
Add the missing module to `hiddenimports` in the spec file

### Binary won't start:
Run with console enabled to see errors:
- Remove `--windowed` flag (Windows)
- Set `console=True` in spec file

### Large binary size:
- Use `--exclude-module` to remove unused modules
- Install and use UPX compression
- Consider using `--onedir` instead of `--onefile` (creates folder with files)
