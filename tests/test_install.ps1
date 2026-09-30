$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
$oldAppData = $env:APPDATA
$oldOS = $env:OS

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# Model WScript shortcuts as files so install/uninstall can be exercised without
# changing the user's Start menu or requiring Windows COM on a development Mac.
function New-Object {
    param([string]$ComObject)
    if ($ComObject -ne "WScript.Shell") { throw "Unexpected COM object: $ComObject" }
    $shell = [pscustomobject]@{}
    $shell | Add-Member ScriptMethod CreateShortcut {
        param($Path)
        $shortcut = [pscustomobject]@{
            Path = $Path
            TargetPath = ""
            Arguments = ""
            WorkingDirectory = ""
            Description = ""
            IconLocation = ""
        }
        if (Test-Path -LiteralPath $Path) {
            $saved = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
            $shortcut.TargetPath = $saved.TargetPath
            $shortcut.Arguments = $saved.Arguments
        }
        $shortcut | Add-Member ScriptMethod Save {
            $this | ConvertTo-Json | Set-Content -LiteralPath $this.Path
        }
        return $shortcut
    }
    return $shell
}

try {
    $env:OS = "Windows_NT"
    $env:APPDATA = Join-Path $temp "App Data"
    $tools = Join-Path $temp "Tools with spaces"
    $startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    & (Join-Path $repo "install.ps1") -ToolsDir $tools -SkipPathCheck
    & (Join-Path $repo "install.ps1") -ToolsDir $tools -SkipPathCheck

    $stub = Join-Path $tools "color-picker.bat"
    $wrapper = Join-Path $tools "color-picker"
    $expected = "wscript.exe `"$(Join-Path $repo 'color-picker.vbs')`" %*"
    Assert-True ((Get-Content -LiteralPath $stub -Raw).Contains($expected)) "Stub must quote this clone's launcher and forward arguments"
    Assert-True (@([IO.File]::ReadAllBytes($stub) | Where-Object { $_ -gt 127 }).Count -eq 0) "Batch stub must be ASCII"
    Assert-True (Test-Path -LiteralPath $wrapper) "Git Bash wrapper is missing"

    $shortcutPaths = @((Join-Path $tools "Color Picker.lnk"))
    foreach ($name in @("Color Picker", "Pixie", "picker")) {
        $shortcutPaths += Join-Path $startMenu "$name.lnk"
    }
    foreach ($path in $shortcutPaths) {
        $shortcut = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        Assert-True ($shortcut.TargetPath -eq "wscript.exe") "Shortcut must use the silent launcher"
        Assert-True ($shortcut.Arguments -eq "`"$(Join-Path $repo 'color-picker.vbs')`"") "Shortcut must target this clone"
        Assert-True ($shortcut.WorkingDirectory -eq $repo) "Shortcut working directory must be this clone"
    }

    $sibling = Join-Path $tools "other-tool.bat"
    Set-Content -LiteralPath $sibling -Value "keep me"
    $alias = Join-Path $startMenu "Pixie.lnk"
    $otherShortcut = New-Object -ComObject WScript.Shell
    $otherShortcut = $otherShortcut.CreateShortcut($alias)
    $otherShortcut.TargetPath = "other-app.exe"
    $otherShortcut.Arguments = "other app"
    $otherShortcut.Save()

    & (Join-Path $repo "uninstall.ps1") -ToolsDir $tools
    Assert-True (-not (Test-Path -LiteralPath $stub)) "Owned stub must be removed"
    Assert-True (-not (Test-Path -LiteralPath $wrapper)) "Owned wrapper must be removed"
    Assert-True (Test-Path -LiteralPath $sibling) "Other tools must survive uninstall"
    Assert-True (Test-Path -LiteralPath $alias) "A shortcut replaced by another app must survive uninstall"
    foreach ($path in $shortcutPaths | Where-Object { $_ -ne $alias }) {
        Assert-True (-not (Test-Path -LiteralPath $path)) "Owned shortcut must be removed"
    }

    & (Join-Path $repo "install.ps1") -ToolsDir $tools -SkipPathCheck
    Set-Content -LiteralPath $wrapper -Value "another command"
    & (Join-Path $repo "uninstall.ps1") -ToolsDir $tools
    Assert-True (Test-Path -LiteralPath $wrapper) "A replaced Bash wrapper must survive uninstall"

    # If another clone has replaced the command, uninstall must leave it alone.
    & (Join-Path $repo "install.ps1") -ToolsDir $tools -SkipPathCheck
    Set-Content -LiteralPath $stub -Value '@echo off
wscript.exe "C:\another clone\color-picker.vbs" %*' -Encoding ASCII
    & (Join-Path $repo "uninstall.ps1") -ToolsDir $tools
    Assert-True (Test-Path -LiteralPath $stub) "Another clone's stub must survive uninstall"
    Assert-True (Test-Path -LiteralPath $wrapper) "Another clone's wrapper must survive uninstall"
    & (Join-Path $repo "uninstall.ps1") -ToolsDir $tools
    Write-Host "color-picker installer tests passed" -ForegroundColor Green
} finally {
    $env:APPDATA = $oldAppData
    $env:OS = $oldOS
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
