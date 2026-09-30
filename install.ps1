# Run again after moving the clone. Generated launchers point at live files.
param(
    [string]$ToolsDir = "C:\dev\tools",
    [switch]$SkipPathCheck
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
if ($env:OS -ne "Windows_NT") { throw "color-picker installs on Windows only." }
. (Join-Path $PSScriptRoot "install-lib.ps1")
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

if (-not $SkipPathCheck) {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $userPath) { $userPath = "" }
    $onPath = ($machinePath -split ";") + ($userPath -split ";") |
        Where-Object { $_.TrimEnd("\") -ieq $ToolsDir.TrimEnd("\") }
    if (-not $onPath) {
        Write-Host "'$ToolsDir' is not on your PATH." -ForegroundColor Yellow
        $answer = Read-Host "Add it to your User PATH now? [Y/n]"
        if ($answer -eq "" -or $answer -imatch "^y") {
            $newPath = ($userPath.TrimEnd(";") + ";$ToolsDir").TrimStart(";")
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:PATH += ";$ToolsDir"
            Write-Host "Added to User PATH. Open a new terminal to use color-picker." -ForegroundColor Green
        }
    }
}

Write-BatStub -ToolName "color-picker" -Content (Get-ColorPickerStubContent $PSScriptRoot) -ToolsDir $ToolsDir
$launcher = Join-Path $PSScriptRoot "color-picker.vbs"
$shell = New-Object -ComObject WScript.Shell
foreach ($path in (Get-ColorPickerShortcutPaths $ToolsDir)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = "wscript.exe"
    $shortcut.Arguments = "`"$launcher`""
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.Description = "Pick screen colors and copy HEX, RGB, HSL, HLS, HSV, CMYK, or BGR values"
    $shortcut.IconLocation = "%SystemRoot%\System32\imageres.dll,109"
    $shortcut.Save()
    Write-Host "  [lnk]  $path" -ForegroundColor Green
}
Write-Host "Installed color-picker. Search for Color Picker, Pixie, or picker in Windows Search." -ForegroundColor Cyan
Write-Host "To pin it, right-click 'Color Picker.lnk' in $ToolsDir and choose Pin to taskbar." -ForegroundColor Cyan
