# Agent guidance for color-picker

This is a Windows screen colour picker built with PowerShell, .NET WinForms
and Win32/GDI. Source files live at the repo root.

## Working rules

- Use test-first development for non-trivial changes. If there is no clean
  test seam, extract one before adding the test.
- Update affected tests when behaviour or expectations change and rerun them
  after implementation.
- Test before committing. Run the core and installer tests, parse every
  PowerShell script, then verify the actual tool on Windows. Check exit codes.
- GUI entry points must use `color-picker.vbs` via `wscript.exe` to avoid a
  flashing console. Never point taskbar shortcuts directly at PowerShell.
- Keep generated `.bat` files ASCII. Quote clone paths and forward arguments.
- Keep source in this repo. `C:\dev\tools` only gets generated launchers and
  shortcuts. Never commit large `.exe` or `.dll` binaries.
- `install.ps1` targets this clone using `$PSScriptRoot`. Rerun it after moving
  the clone or changing installation wiring. Source edits need no reinstall.
- Uninstall must remove only launchers owned by this clone. Preserve other
  tools, shared directories, PATH entries and Explorer menu entries.
- No API keys, package installation or `deps.ps1` are needed.
- Keep comments explaining unusual launcher, ownership or native API behaviour.
- Do not add decorative eyebrow or kicker text to the UI.

## Files

- `ColorPickerCore.ps1`: pure colour conversion, formatting and contrast logic.
- `color-picker.ps1`: WinForms UI and Win32/GDI screen sampling.
- `color-picker.vbs`: silent launcher. Waits and forwards exit codes for
  `-SelfTest` and `-SmokeTest`.
- `install-lib.ps1`: launcher generation and shortcut-path helpers.
- `install.ps1`: command, Git Bash wrapper and Windows Search shortcuts.
- `uninstall.ps1`: ownership-aware removal.

## Verification

From the repo root on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\check-syntax.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_color_picker_core.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\color-picker.ps1 -SelfTest
powershell -NoProfile -ExecutionPolicy Bypass -File .\color-picker.ps1 -SmokeTest
wscript.exe .\color-picker.vbs -SelfTest
```

Syntax, core and installer tests also run with `pwsh` on macOS. Installer tests
use a file-backed shortcut mock and temporary directories. They do not prove
real COM shortcuts, PATH updates or screen sampling work. Native self-tests,
smoke tests, drag-to-pick and clipboard checks require Windows. CI uses Windows
PowerShell, the same runtime as the VBS launcher.
