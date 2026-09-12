<#
.SYNOPSIS
    Backs up existing Antigravity configuration files.
#>
[CmdletBinding()]
param (
    [string]$TargetDir = "$env:USERPROFILE\.gemini\config"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $TargetDir "backups\$timestamp"

if (-not (Test-Path $TargetDir)) {
    Write-Host "[INFO] Antigravity config directory not found ($TargetDir). Skipping backup." -ForegroundColor Yellow
    return
}

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$filesToBackup = @("GEMINI.md", "mcp_config.json", "config.json")
$backedUpCount = 0

foreach ($file in $filesToBackup) {
    $filePath = Join-Path $TargetDir $file
    if (Test-Path $filePath) {
        $destPath = Join-Path $backupDir $file
        Copy-Item -Path $filePath -Destination $destPath -Force
        Write-Host "[BACKUP] Saved $file -> $destPath" -ForegroundColor Green
        $backedUpCount++
    }
}

if ($backedUpCount -gt 0) {
    Write-Host "[SUCCESS] Backed up $backedUpCount config file(s) to $backupDir" -ForegroundColor Cyan
} else {
    Write-Host "[INFO] No existing config files found to back up." -ForegroundColor Gray
}
