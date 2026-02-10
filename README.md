# NumpadStrategems

NumpadStrategems is a cross-platform desktop app for Helldivers 2 that lets you trigger strategem codes using Ctrl + Numpad hotkeys. It provides a compact on-screen panel with icon tiles, status hints, and configurable input timing so you can call strategems quickly and consistently.

## What it does

- Assign strategems to numpad keys and trigger them with Ctrl + Numpad
- Simulate either WASD or arrow key sequences for strategem input
- Auto-download and cache strategem icons
- Adjustable input delay for more reliable in-game recognition
- Works on Windows and Linux (Wayland/XWayland supported)

## Downloads

Grab the latest release binaries from:
https://github.com/EatPrilosec/NumpadStrategems/releases

## Requirements (from source)

If you want to run from source instead of a binary:
- Python 3.10+
- Dependencies in requirements.txt

## Notes

- On Linux, the app will prompt for elevation when needed to read global input devices.
- Strategem icons are downloaded on first run and cached locally.

## Reset Settings and Cache

If you need to clear all settings and cached icons, focus the app window and type:

```
sixseven
```

The app will delete its local app data and restart automatically.
