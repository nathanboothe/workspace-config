<#
.SYNOPSIS
    Merges shared-settings.json into the "settings" block of every
    .code-workspace file in this repo, overwriting whatever was there.
#>

$repoConfigPath = $PSScriptRoot
$sharedSettingsPath = Join-Path $repoConfigPath "shared-settings.json"

if (-not (Test-Path $sharedSettingsPath)) {
    Write-Error "shared-settings.json not found at $sharedSettingsPath"
    exit 1
}

$sharedSettings = Get-Content $sharedSettingsPath -Raw | ConvertFrom-Json

$workspaceFiles = Get-ChildItem -Path $repoConfigPath -Filter "*.code-workspace"

if ($workspaceFiles.Count -eq 0) {
    Write-Warning "No .code-workspace files found in $repoConfigPath"
    exit 0
}

foreach ($file in $workspaceFiles) {
    Write-Host "Updating $($file.Name)..."

    $workspace = Get-Content $file.FullName -Raw | ConvertFrom-Json

    # Overwrite the settings block with the shared version
    $workspace | Add-Member -MemberType NoteProperty -Name "settings" -Value $sharedSettings -Force

    $json = $workspace | ConvertTo-Json -Depth 10
    Set-Content -Path $file.FullName -Value $json -Encoding UTF8
}

Write-Host "`nDone. Updated $($workspaceFiles.Count) workspace file(s)." -ForegroundColor Green