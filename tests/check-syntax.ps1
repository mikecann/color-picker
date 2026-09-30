$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$failed = $false
foreach ($file in (Get-ChildItem -LiteralPath $repo -Recurse -Filter *.ps1 -File)) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $failed = $true
        Write-Host $file.FullName -ForegroundColor Red
        $parseErrors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
    }
}
if ($failed) { throw "PowerShell parse checks failed." }
Write-Host "All PowerShell files parsed successfully." -ForegroundColor Green
