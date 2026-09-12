<#
.SYNOPSIS
    Environment Verification Script for Antigravity AI Agent Development Setup.
#>
[CmdletBinding()]
param (
    [string]$ConfigDir = "$env:USERPROFILE\.gemini\config"
)

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "       Antigravity Environment Verification" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Ensure user local bin and antigravity bin are in PATH for this session
$extraPaths = @(
    "$env:USERPROFILE\.local\bin",
    "$env:USERPROFILE\.gemini\antigravity\bin"
)
foreach ($p in $extraPaths) {
    if ((Test-Path $p) -and ($env:PATH -notlike "*$p*")) {
        $env:PATH = "$p;$env:PATH"
    }
}

function Check-Tool {
    param ([string]$Name, [string]$CommandName, [string]$VersionArg = "--version")
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($cmd) {
        try {
            $out = & $cmd.Source $VersionArg 2>&1 | Out-String
            $validLines = ($out -split "[\r\n]+") | Where-Object { $_ -notmatch "RuntimeWarning|UserWarning|site-packages|pydub" -and $_.Trim() -ne "" }
            $line = if ($validLines) { $validLines[0].Trim() } else { "Available" }
            Write-Host ("[CLI] {0,-12} : {1}" -f $Name, $line) -ForegroundColor Gray
            return $true
        } catch {
            Write-Host ("[CLI] {0,-12} : Available" -f $Name) -ForegroundColor Gray
            return $true
        }
    }
    Write-Host ("[CLI] {0,-12} : NOT FOUND" -f $Name) -ForegroundColor Yellow
    return $false
}

Write-Host "`n--- Checking CLI Tools ---" -ForegroundColor Cyan
[void](Check-Tool "Git" "git")
[void](Check-Tool "Node.js" "node")
[void](Check-Tool "npm" "npm")
[void](Check-Tool "npx" "npx")
[void](Check-Tool "uv" "uv")
[void](Check-Tool "uvx" "uvx")
[void](Check-Tool "Semgrep" "semgrep")
$hasMarkItDown = Check-Tool "MarkItDown" "markitdown"
$hasMinerU = Check-Tool "MinerU" "mineru"

function Test-FileHasUtf8Bom {
    param ([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return $true
    }
    return $false
}

# Check Antigravity Configurations
Write-Host "`n--- Checking Antigravity Configuration & Encodings ---" -ForegroundColor Cyan

$mcpConfigFile = Join-Path $ConfigDir "mcp_config.json"
$rulesFile = Join-Path $ConfigDir "GEMINI.md"
$superpowersDir = Join-Path $ConfigDir "plugins\superpowers"

$mcpJson = $null
$jsonValid = $false
$bomClean = $true
if (Test-Path $mcpConfigFile) {
    # 1. UTF-8 BOM Check
    if (Test-FileHasUtf8Bom $mcpConfigFile) {
        Write-Host "[FAIL] mcp_config.json contains UTF-8 BOM (Breaks python/standard parsers)" -ForegroundColor Red
        $bomClean = $false
    } else {
        Write-Host "[OK] mcp_config.json is UTF-8 without BOM" -ForegroundColor Green
    }

    # 2. JSON Syntax Check
    try {
        $mcpRaw = [System.IO.File]::ReadAllText($mcpConfigFile, [System.Text.Encoding]::UTF8)
        $mcpJson = $mcpRaw | ConvertFrom-Json
        $jsonValid = $true
        Write-Host "[OK] mcp_config.json is valid JSON" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] mcp_config.json contains invalid JSON: $_" -ForegroundColor Red
    }

    # 3. Pinned Version Check (No @latest)
    if ($mcpRaw -match "@latest") {
        Write-Host "[WARN] mcp_config.json contains unpinned '@latest' reference(s). Configuration may drift." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] mcp_config.json has NO floating '@latest' tags" -ForegroundColor Green
    }
} else {
    Write-Host "[FAIL] mcp_config.json does not exist at $mcpConfigFile" -ForegroundColor Red
}

if (Test-Path $rulesFile) {
    if (Test-FileHasUtf8Bom $rulesFile) {
        Write-Host "[FAIL] GEMINI.md contains UTF-8 BOM" -ForegroundColor Red
        $bomClean = $false
    } else {
        Write-Host "[OK] GEMINI.md is UTF-8 without BOM" -ForegroundColor Green
    }
}

# Evaluate Status
$status = [ordered]@{}

if ($jsonValid -and $mcpJson.mcpServers) {
    $servers = $mcpJson.mcpServers

    # Serena
    $status["Serena"] = if ($servers.serena) { "OK" } else { "MISSING" }

    # Context7
    $status["Context7"] = if ($servers.context7) { "OK (Remote)" } else { "MISSING" }

    # Playwright
    $status["Playwright"] = if ($servers.playwright) { "OK" } else { "MISSING" }

    # GitHub MCP
    if ($servers.github) {
        $auth = $servers.github.headers.Authorization
        if ($auth -and (-not $auth.Contains("YOUR_GITHUB_PAT"))) {
            $status["GitHub MCP"] = "Configured (Remote)"
        } else {
            $status["GitHub MCP"] = "Needs Authentication (Remote)"
        }
    } else {
        $status["GitHub MCP"] = "MISSING"
    }

    # Chrome DevTools
    $status["Chrome DevTools"] = if ($servers."chrome-devtools") { "OK" } else { "MISSING" }

    # Semgrep
    $status["Semgrep"] = if ($servers.semgrep) { "OK" } else { "MISSING" }

    # Docling
    $status["Docling MCP"] = if ($servers.docling) { "OK" } else { "MISSING" }
}

$status["UTF-8 No-BOM"] = if ($bomClean) { "OK" } else { "FAIL (BOM Detected)" }
$status["MarkItDown"] = if ($hasMarkItDown) { "OK" } else { "Optional (Not Installed)" }
$status["MinerU Local"] = if ($hasMinerU) { "OK" } else { "Optional (Not Installed)" }
$status["Superpowers"] = if (Test-Path $superpowersDir) { "OK" } else { "MISSING" }
$status["Global Rules"] = if (Test-Path $rulesFile) { "OK" } else { "MISSING" }

# --- Skills Verification ---
$skillsDir = Join-Path $ConfigDir "skills"
$bootstrapSkill = Join-Path $skillsDir "project-bootstrap\SKILL.md"
$auditSkill     = Join-Path $skillsDir "release-audit\SKILL.md"
$status["Project Bootstrap Skill"] = if (Test-Path $bootstrapSkill) { "OK" } else { "MISSING — run install.ps1" }
$status["Release Audit Skill"]     = if (Test-Path $auditSkill)     { "OK" } else { "MISSING — run install.ps1" }

# --- Hooks Verification ---
$hooksDir         = Join-Path $ConfigDir "hooks"
$preGuard         = Join-Path $hooksDir "pre_tool_guard.py"
$postGuard        = Join-Path $hooksDir "post_tool_guard.py"
$stopGuard        = Join-Path $hooksDir "stop_guard.py"
$globalHooksJson  = Join-Path $ConfigDir "hooks.json"

$status["pre_tool_guard.py"]  = if (Test-Path $preGuard)  { "OK" } else { "MISSING — run install.ps1" }
$status["post_tool_guard.py"] = if (Test-Path $postGuard) { "OK" } else { "MISSING — run install.ps1" }
$status["stop_guard.py"]      = if (Test-Path $stopGuard) { "OK" } else { "MISSING — run install.ps1" }

# Check hooks.json has harness entries and their targets exist
$harnessOk = $false
$hookPathsOk = $true
if (Test-Path $globalHooksJson) {
    try {
        $hooksContent = Get-Content $globalHooksJson -Raw -Encoding UTF8 | ConvertFrom-Json
        $hasPreGuard  = $null -ne $hooksContent."harness-pre-tool-guard"
        $hasPostGuard = $null -ne $hooksContent."harness-post-tool-guard"
        $hasStopGuard = $null -ne $hooksContent."harness-stop-guard"
        $harnessOk = $hasPreGuard -and $hasPostGuard -and $hasStopGuard
        # Check that command targets actually exist on disk
        $hooksContent.PSObject.Properties | ForEach-Object {
            $hookDef = $_.Value
            foreach ($phase in @("PreToolUse", "PostToolUse", "Stop")) {
                $phaseData = $hookDef.$phase
                if ($null -eq $phaseData) { continue }
                $items = if ($phaseData -is [System.Array]) { $phaseData } else { @($phaseData) }
                foreach ($item in $items) {
                    $hooksArr = if ($null -ne $item.hooks) { $item.hooks } else { @($item) }
                    foreach ($h in $hooksArr) {
                        if ($null -ne $h.command) {
                            # Extract path from: python "C:\path\to\script.py"
                            if ($h.command -match 'python\s+"?([^"]+\.py)"?') {
                                $scriptPath = $Matches[1].Trim()
                                if (-not (Test-Path $scriptPath)) {
                                    Write-Host ("[WARN] Hook command target not found: $scriptPath") -ForegroundColor Yellow
                                    $hookPathsOk = $false
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Host "[WARN] Could not parse global hooks.json: $_" -ForegroundColor Yellow
    }
}
$status["Harness Hooks (hooks.json)"] = if ($harnessOk) { "OK" } else { "MISSING entries — run install.ps1" }
$status["Hook Paths (targets exist)"] = if ($hookPathsOk) { "OK" } else { "FAIL — some command targets missing" }


Write-Host "`n===================================================" -ForegroundColor Cyan
Write-Host "                Verification Summary" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

foreach ($key in $status.Keys) {
    $val = $status[$key]
    $color = if ($val -like "*OK*" -or $val -eq "Configured") { "Green" } elseif ($val -like "*Optional*") { "DarkGray" } else { "Yellow" }
    Write-Host ("{0,-20} : {1}" -f $key, $val) -ForegroundColor $color
}
Write-Host "===================================================" -ForegroundColor Cyan
