function Get-ColorPickerStubContent {
    param([string]$RepoDir)
    $launcher = Join-Path $RepoDir "color-picker.vbs"
    return "@echo off`r`nwscript.exe `"$launcher`" %*"
}

function Get-BashStubContent {
    param([string]$ToolName)
    return @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace("__TOOL_NAME__", $ToolName)
}

# Also provide the Git Bash wrapper used by the original installer.
function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    $batDest = Join-Path $ToolsDir "$ToolName.bat"
    Set-Content -LiteralPath $batDest -Value $Content -Encoding ASCII
    Write-Host "  [bat]  $batDest" -ForegroundColor Green
    $bashDest = Join-Path $ToolsDir $ToolName
    Set-Content -LiteralPath $bashDest -Value (Get-BashStubContent $ToolName) -Encoding ASCII
    Write-Host "  [bash] $bashDest" -ForegroundColor Green
}

function Get-ColorPickerShortcutPaths {
    param([string]$ToolsDir)
    Join-Path $ToolsDir "Color Picker.lnk"
    foreach ($name in @("Color Picker", "Pixie", "picker")) {
        Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$name.lnk"
    }
}
