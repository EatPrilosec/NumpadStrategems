# Release Instructions

## Automatic Release via GitHub Actions

The project is set up to automatically build and release binaries for both Windows and Linux.

### Creating a New Release

1. **Tag your commit with a version number:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build the Linux binary on Ubuntu
   - Build the Windows binary on Windows Server
   - Create a new GitHub Release
   - Attach both binaries to the release
   - Generate release notes from your commits

3. **Find your release at:**
   `https://github.com/YOUR_USERNAME/NumpadStrategems/releases`

### Manual Trigger

You can also trigger a build manually without creating a tag:

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build and Release Binaries** workflow
3. Click **Run workflow**
4. Choose the branch and click **Run workflow**

Note: Manual triggers will create artifacts but won't create a release (modify the workflow if you need this).

## Version Naming Convention

Use semantic versioning for tags:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release (new features)
- `v1.0.1` - Patch release (bug fixes)
- `v1.0.0-beta1` - Pre-release versions

## What Gets Built

- **Linux**: `NumpadStrategems` - Standalone executable for Linux (x64)
- **Windows**: `NumpadStrategems.exe` - Standalone executable for Windows (x64)

Both binaries include:
- Python interpreter
- All dependencies (PyQt6, pynput, etc.)
- `Resupply.ico` as the application icon
- No external dependencies required!

## Troubleshooting

### Build fails on Linux
- Check that all dependencies in `requirements.txt` are compatible with Linux
- Verify the `Resupply.ico` file exists

### Build fails on Windows
- Same as above, plus check Windows-specific imports

### Release not created
- Ensure the tag starts with `v` (e.g., `v1.0.0`)
- Check that you pushed the tag: `git push origin v1.0.0`
- Verify repository permissions allow GitHub Actions to create releases

## Local Testing

Test the build process locally before pushing:

**Linux:**
```bash
python build_binary.py
./dist/NumpadStrategems
```

**Windows:**
```cmd
python build_binary.py
dist\NumpadStrategems.exe
```
