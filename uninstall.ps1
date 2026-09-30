param([string]$ToolsDir = "C:\dev\tools")

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
if ($env:OS -ne "Windows_NT") { throw "color-picker uninstalls on Windows only." }
. (Join-Path $PSScriptRoot "install-lib.ps1")
$stub = Join-Path $ToolsDir "color-picker.bat"
$expected = Get-ColorPickerStubContent $PSScriptRoot

# The shared command may have been replaced by another clone. Remove its
# wrapper only if the companion batch file still belongs to this clone.
if ((Test-Path -LiteralPath $stub) -and
    (Get-Content -LiteralPath $stub -Raw).Trim() -eq $expected.Trim()) {
    Remove-Item -LiteralPath $stub
    $wrapper = Join-Path $ToolsDir "color-picker"
    if ((Test-Path -LiteralPath $wrapper) -and
        (Get-Content -LiteralPath $wrapper -Raw).Trim() -eq (Get-BashStubContent "color-picker").Trim()) {
        Remove-Item -LiteralPath $wrapper
    }
}

$launcher = Join-Path $PSScriptRoot "color-picker.vbs"
$shell = New-Object -ComObject WScript.Shell
foreach ($path in (Get-ColorPickerShortcutPaths $ToolsDir)) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $shortcut = $shell.CreateShortcut($path)
    if ((Split-Path -Leaf $shortcut.TargetPath) -ieq "wscript.exe" -and
        $shortcut.Arguments -eq "`"$launcher`"") {
        Remove-Item -LiteralPath $path
        Write-Host "Removed $path" -ForegroundColor Green
    }
}
# The tools directory and its PATH entry are shared, so keep them.
Write-Host "Removed launchers belonging to this color-picker clone." -ForegroundColor Cyan
