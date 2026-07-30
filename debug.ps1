
<#
.SYNOPSIS
    DEBUG VERSION - traces every step to find where it's silently failing.
#>
 
Write-Host "=== SCRIPT STARTED ===" -ForegroundColor Cyan
 
$ErrorActionPreference = "Continue"
 
Write-Host "PSScriptRoot is: '$PSScriptRoot'" -ForegroundColor Yellow
 
$repoConfigPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($repoConfigPath)) {
    Write-Host "PSScriptRoot is EMPTY - falling back to current directory" -ForegroundColor Red
    $repoConfigPath = Get-Location
}
 
Write-Host "Using repoConfigPath: '$repoConfigPath'" -ForegroundColor Yellow
 
$sharedSettingsPath = Join-Path $repoConfigPath "shared-settings.json"
Write-Host "Looking for shared settings at: '$sharedSettingsPath'" -ForegroundColor Yellow
 
if (-not (Test-Path $sharedSettingsPath)) {
    Write-Host "ERROR: shared-settings.json NOT FOUND at that path." -ForegroundColor Red
    Write-Host "Contents of repoConfigPath:" -ForegroundColor Yellow
    Get-ChildItem -Path $repoConfigPath | Format-Table Name, Length
    Read-Host "Press Enter to exit"
    exit 1
}
 
Write-Host "Found shared-settings.json. Reading it..." -ForegroundColor Green
 
try {
    $rawContent = Get-Content $sharedSettingsPath -Raw
    Write-Host "Raw content length: $($rawContent.Length) characters" -ForegroundColor Yellow
    $sharedSettings = $rawContent | ConvertFrom-Json
    Write-Host "Successfully parsed shared-settings.json" -ForegroundColor Green
}
catch {
    Write-Host "ERROR parsing shared-settings.json:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
 
Write-Host "Looking for .code-workspace files in: '$repoConfigPath'" -ForegroundColor Yellow
$workspaceFiles = Get-ChildItem -Path $repoConfigPath -Filter "*.code-workspace"
 
Write-Host "Found $($workspaceFiles.Count) workspace file(s)" -ForegroundColor Yellow
if ($workspaceFiles.Count -gt 0) {
    $workspaceFiles | ForEach-Object { Write-Host "  - $($_.Name)" }
}
 
if ($workspaceFiles.Count -eq 0) {
    Write-Host "No .code-workspace files found. Listing all files in folder instead:" -ForegroundColor Red
    Get-ChildItem -Path $repoConfigPath | Format-Table Name, Extension
    Read-Host "Press Enter to exit"
    exit 0
}
 
foreach ($file in $workspaceFiles) {
    Write-Host "`nProcessing: $($file.Name)" -ForegroundColor Cyan
    try {
        $workspaceRaw = Get-Content $file.FullName -Raw
        Write-Host "  Read $($workspaceRaw.Length) characters"
 
        $workspace = $workspaceRaw | ConvertFrom-Json
        Write-Host "  Parsed JSON successfully"
 
        $workspace | Add-Member -MemberType NoteProperty -Name "settings" -Value $sharedSettings -Force
        Write-Host "  Settings property updated in memory"
 
        $json = $workspace | ConvertTo-Json -Depth 10
        Set-Content -Path $file.FullName -Value $json -Encoding UTF8
        Write-Host "  WROTE updated file successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  ERROR processing $($file.Name):" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
}
 
Write-Host "`n=== SCRIPT FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to close"
 
