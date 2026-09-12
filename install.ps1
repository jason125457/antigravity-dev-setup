<#
.SYNOPSIS
    Master Bootstrap Installer for Antigravity AI Agent Development Environment.
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -DryRun
.EXAMPLE
    .\install.ps1 -InstallDocumentTools
#>
[CmdletBinding()]
param (
    [switch]$DryRun,
    [switch]$InstallDocumentTools,
    [switch]$InstallMarkItDown,
    [switch]$InstallMinerU,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host @"
===================================================================
      Antigravity AI Agent Development Environment Bootstrap
===================================================================
Target OS: Windows 10 / 11
Core MCPs: Serena (pinned), Context7, Playwright (pinned), GitHub,
           Chrome DevTools (pinned), Semgrep (pinned), Docling (pinned)
Plugin:    Superpowers (obra/superpowers pinned to commit b36e082)
Doc CLIs:  MarkItDown (Recommended), MinerU Local (Optional)
===================================================================
"@ -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY-RUN MODE] Simulating execution without altering files." -ForegroundColor Yellow
}

$scriptDir = $PSScriptRoot

# 1. Backup Existing Configs
Write-Host "`n[Step 1/4] Backing up existing configurations..." -ForegroundColor Cyan
if (-not $DryRun) {
    & "$scriptDir\scripts\backup-existing-config.ps1"
} else {
    Write-Host "[DRY-RUN] Would back up ~/.gemini/config/GEMINI.md, mcp_config.json, config.json" -ForegroundColor Gray
}

# 2. Check & Install Prerequisites
Write-Host "`n[Step 2/4] Verifying CLI prerequisites..." -ForegroundColor Cyan
if (-not $DryRun) {
    & "$scriptDir\scripts\install-prerequisites.ps1" -NonInteractive:$NonInteractive
} else {
    Write-Host "[DRY-RUN] Would verify/install Git, Node.js, npm, npx, uv, uvx, semgrep==1.177.0." -ForegroundColor Gray
}

# 3. Handle Document CLI Options
$installMD = $InstallDocumentTools -or $InstallMarkItDown
$installMU = $InstallDocumentTools -or $InstallMinerU

if ((-not $NonInteractive) -and (-not $DryRun) -and (-not $InstallDocumentTools) -and (-not $InstallMarkItDown) -and (-not $InstallMinerU)) {
    Write-Host "`n--- Optional Document Intelligence CLIs ---" -ForegroundColor Yellow
    Write-Host "Docling MCP is included in Core MCPs for structured parsing."
    $ansMD = Read-Host "Install Microsoft MarkItDown CLI (Recommended)? (y/N)"
    if ($ansMD -match "^[yY]") { $installMD = $true }

    $ansMU = Read-Host "Install MinerU Local CLI (Optional, heavy dependencies ~1.5GB)? (y/N)"
    if ($ansMU -match "^[yY]") { $installMU = $true }
}

# 4. Install MCPs, Plugins, Rules, Skills & Hooks
Write-Host "`n[Step 3/4] Installing Core MCPs, Plugins, Global Rules, Skills & Hooks..." -ForegroundColor Cyan
if (-not $DryRun) {
    & "$scriptDir\scripts\install-mcp.ps1" `
        -InstallMarkItDown:$installMD `
        -InstallMinerU:$installMU `
        -NonInteractive:$NonInteractive
} else {
    $hooksDeployDir = "$env:USERPROFILE\.gemini\config\hooks\"
    $skillsDeployDir = "$env:USERPROFILE\.gemini\config\skills\"
    Write-Host "[DRY-RUN] Would merge 7 MCPs with pinned versions to ~/.gemini/config/mcp_config.json (UTF-8 No-BOM)" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would clone/checkout obra/superpowers commit b36e082" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would apply GEMINI.md global rules (UTF-8 No-BOM)" -ForegroundColor Gray
    Write-Host "[DRY-RUN] GitHub PAT will be read from `$env:GITHUB_PAT or interactive secure prompt (no plaintext cli arg)" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would deploy skills/project-bootstrap/ to $skillsDeployDir" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would deploy skills/release-audit/    to $skillsDeployDir" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would deploy hooks/*.py to $hooksDeployDir (absolute command paths)" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would backup ~/.gemini/config/hooks.json to hooks.json.bak" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would merge harness hook entries into ~/.gemini/config/hooks.json (safe — preserves existing user hooks)" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Project template available at: $scriptDir\templates\project-template\" -ForegroundColor Gray
    if ($installMD) { Write-Host "[DRY-RUN] Would install MarkItDown CLI 0.1.7 via uv tool" -ForegroundColor Gray }
    if ($installMU) { Write-Host "[DRY-RUN] Would install MinerU Local 3.4.5 via uv tool and run compatibility test" -ForegroundColor Gray }
}

# 5. Run Verification
Write-Host "`n[Step 4/4] Verifying installation..." -ForegroundColor Cyan
if (-not $DryRun) {
    & "$scriptDir\verify.ps1"
} else {
    Write-Host "[DRY-RUN] Would execute verify.ps1" -ForegroundColor Gray
}

Write-Host @"

===================================================================
                      Bootstrap Finished!
===================================================================
Next Steps:
1. Restart Antigravity IDE / CLI to reload MCP servers and rules.
2. Check Antigravity Customization Settings to confirm all 7 MCPs
   are active and connected.
3. Global Skills deployed to: $env:USERPROFILE\.gemini\config\skills\
   - project-bootstrap  (use when starting a new project)
   - release-audit      (use before any release / PR)
4. Project template available at:
   $scriptDir\templates\project-template\
   Copy to new project root or reference via project-bootstrap Skill.
===================================================================
"@ -ForegroundColor Green

