<#
.SYNOPSIS
    Installs MCP servers, Superpowers plugin, global rules, skills, hooks,
    and optional document CLIs.
#>
[CmdletBinding()]
param (
    [string]$ConfigDir = "$env:USERPROFILE\.gemini\config",
    [string]$TemplatePath = "",
    [string]$RulesSource = "",
    [string]$SkillsSource = "",
    [string]$HooksSource = "",
    [string]$HooksJsonSource = "",
    [switch]$InstallMarkItDown,
    [switch]$InstallMinerU,
    [switch]$NonInteractive,
    [switch]$DryRun
)

function Set-ContentUtf8NoBom {
    param (
        [Parameter(Mandatory=$true)] [string]$Path,
        [Parameter(Mandatory=$true)] [string]$Content
    )
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and (-not (Test-Path $dir))) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($TemplatePath) -or (-not (Test-Path $TemplatePath))) {
    $TemplatePath = Join-Path $repoRoot "config\mcp_config.template.json"
}
if ([string]::IsNullOrWhiteSpace($RulesSource) -or (-not (Test-Path $RulesSource))) {
    $RulesSource = Join-Path $repoRoot "config\GEMINI.md"
}
if ([string]::IsNullOrWhiteSpace($SkillsSource) -or (-not (Test-Path $SkillsSource))) {
    $SkillsSource = Join-Path $repoRoot "skills"
}
if ([string]::IsNullOrWhiteSpace($HooksSource) -or (-not (Test-Path $HooksSource))) {
    $HooksSource = Join-Path $repoRoot "hooks"
}
if ([string]::IsNullOrWhiteSpace($HooksJsonSource) -or (-not (Test-Path $HooksJsonSource))) {
    $HooksJsonSource = Join-Path $repoRoot "config\hooks.json"
}

# --- Helper: Safe JSON merge for hooks.json ---
# Merges source hook entries into the target hooks.json, preserving all existing
# third-party / user hooks. Reports conflicts but never deletes unknown entries.
function Merge-HooksJson {
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$BackupPath,
        [string]$HooksDir = ""
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    if ([string]::IsNullOrWhiteSpace($HooksDir)) {
        $HooksDir = Join-Path ([System.Environment]::GetFolderPath("UserProfile")) ".gemini\config\hooks"
    }
    $cleanHooksDir = $HooksDir.Replace("\", "/")

    # Read source
    $srcRaw = [System.IO.File]::ReadAllText($SourcePath, [System.Text.Encoding]::UTF8)
    $srcJson = $srcRaw | ConvertFrom-Json

    # Read or create target
    $tgtJson = $null
    if (Test-Path $TargetPath) {
        # Backup first
        [System.IO.File]::Copy($TargetPath, $BackupPath, $true)
        Write-Host "[INFO] Backed up existing hooks.json to $BackupPath" -ForegroundColor Gray
        try {
            $tgtRaw = [System.IO.File]::ReadAllText($TargetPath, [System.Text.Encoding]::UTF8)
            $tgtJson = $tgtRaw | ConvertFrom-Json
        } catch {
            Write-Host "[WARN] Existing hooks.json could not be parsed. Starting fresh from source." -ForegroundColor Yellow
            $tgtJson = [PSCustomObject]@{}
        }
    } else {
        $tgtJson = [PSCustomObject]@{}
    }

    # Merge: add/update source entries; preserve all others
    foreach ($prop in $srcJson.PSObject.Properties) {
        $hookId = $prop.Name
        $hookVal = $prop.Value

        # Rewrite command paths to absolute with forward slashes so CWD doesn't matter at runtime
        foreach ($phase in @("PreToolUse", "PostToolUse", "Stop")) {
            $phaseData = $hookVal.$phase
            if ($null -eq $phaseData) { continue }
            $items = if ($phaseData -is [System.Array]) { $phaseData } else { @($phaseData) }
            foreach ($item in $items) {
                $hooksArr = $item.hooks
                if ($null -eq $hooksArr) { $hooksArr = @($item) }
                foreach ($h in $hooksArr) {
                    if ($h.command -match "\./hooks/(.+\.py)") {
                        $scriptName = $Matches[1]
                        $absPath = "$cleanHooksDir/$scriptName"
                        $h.command = "python $absPath"
                    }
                }
            }
        }
        # Also handle Stop array directly (no nested hooks key)
        $stopData = $hookVal.Stop
        if ($null -ne $stopData) {
            $stopItems = if ($stopData -is [System.Array]) { $stopData } else { @($stopData) }
            foreach ($item in $stopItems) {
                if ($item.command -match "\./hooks/(.+\.py)") {
                    $scriptName = $Matches[1]
                    $absPath = "$cleanHooksDir/$scriptName"
                    $item.command = "python $absPath"
                }
            }
        }

        if ($null -ne $tgtJson.$hookId) {
            Write-Host "[CONFLICT] Hook entry '$hookId' already exists — updating with harness version." -ForegroundColor Yellow
        }
        if ($null -ne $tgtJson.PSObject.Properties[$hookId]) {
            $tgtJson.PSObject.Properties.Remove($hookId)
        }
        $tgtJson | Add-Member -Name $hookId -Value $hookVal -MemberType NoteProperty -Force
        Write-Host "[MERGE] Hook entry '$hookId' merged into global hooks.json" -ForegroundColor Green
    }

    $outJson = $tgtJson | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($TargetPath, $outJson, $utf8NoBom)
}

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

# --- 1. MCP Configuration Merge ---
Write-Host "`n--- Configuring MCP Servers ---" -ForegroundColor Cyan
$targetMcpConfig = Join-Path $ConfigDir "mcp_config.json"
$templateJson = Get-Content $TemplatePath -Raw -Encoding UTF8 | ConvertFrom-Json

$existingJson = $null
if (Test-Path $targetMcpConfig) {
    try {
        $existingJson = Get-Content $targetMcpConfig -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Host "[INFO] Found existing mcp_config.json, merging settings..." -ForegroundColor Gray
    } catch {
        Write-Host "[WARN] Existing mcp_config.json could not be parsed. Starting fresh." -ForegroundColor Yellow
    }
}

if ($null -eq $existingJson) {
    $existingJson = [PSCustomObject]@{
        mcpServers = [PSCustomObject]@{}
    }
}

# Preserve or set GitHub PAT (Secure resolution: Env var > Existing Config > Interactive Secure Prompt)
$patToUse = ""
if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_PAT)) {
    $patToUse = $env:GITHUB_PAT.Trim()
    Write-Host "[INFO] Using GitHub PAT from environment variable GITHUB_PAT." -ForegroundColor Green
} elseif ($null -ne $existingJson.mcpServers.github) {
    $authHeader = $existingJson.mcpServers.github.headers.Authorization
    if ($authHeader -and (-not $authHeader.Contains("YOUR_GITHUB_PAT"))) {
        $patToUse = $authHeader.Replace("Bearer ", "").Trim()
        Write-Host "[INFO] Preserved existing GitHub PAT from local configuration." -ForegroundColor Green
    }
}

if ([string]::IsNullOrWhiteSpace($patToUse) -and (-not $NonInteractive)) {
    Write-Host "[AUTH] GitHub MCP requires a Personal Access Token (PAT) for repository/PR access." -ForegroundColor Yellow
    $secInput = Read-Host "Enter GitHub PAT [input masked, press Enter to skip]" -AsSecureString
    if ($null -ne $secInput -and $secInput.Length -gt 0) {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secInput)
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        if (-not [string]::IsNullOrWhiteSpace($plain)) {
            $patToUse = $plain.Trim()
            Write-Host "[INFO] GitHub PAT received securely." -ForegroundColor Green
        }
    }
}

# Merge all servers from template
foreach ($prop in $templateJson.mcpServers.PSObject.Properties) {
    $serverName = $prop.Name
    $serverConfig = $prop.Value

    # Replace PAT placeholder if available
    if ($serverName -eq "github") {
        if (-not [string]::IsNullOrWhiteSpace($patToUse)) {
            $serverConfig.headers.Authorization = "Bearer $patToUse"
        } else {
            Write-Host "[INFO] GitHub PAT not provided. GitHub MCP will be set to 'Needs Authentication'." -ForegroundColor Yellow
        }
    }

    if ($null -ne $existingJson.mcpServers.$serverName) {
        $existingJson.mcpServers.$serverName = $serverConfig
        Write-Host "[UPDATE] Updated MCP server: $serverName" -ForegroundColor Green
    } else {
        $existingJson.mcpServers | Add-Member -Name $serverName -Value $serverConfig -MemberType NoteProperty -Force
        Write-Host "[NEW] Added MCP server: $serverName" -ForegroundColor Green
    }
}

$jsonOut = $existingJson | ConvertTo-Json -Depth 10
Set-ContentUtf8NoBom -Path $targetMcpConfig -Content $jsonOut
Write-Host "[SUCCESS] MCP configuration saved to $targetMcpConfig (UTF-8 No-BOM)" -ForegroundColor Green

# --- 2. Install Superpowers Plugin (Pinned Commit) ---
Write-Host "`n--- Installing Superpowers Plugin ---" -ForegroundColor Cyan
$pluginsDir = Join-Path $ConfigDir "plugins"
$superpowersDir = Join-Path $pluginsDir "superpowers"
$superpowersCommit = "b36e0829c6d0140e93cfef2ca599b1b07d4a7797"

if (-not (Test-Path $pluginsDir)) {
    New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
}

if (Test-Path (Join-Path $superpowersDir ".git")) {
    Write-Host "[UPDATE] Superpowers plugin exists. Checking out tested commit $superpowersCommit..." -ForegroundColor Gray
    git -C $superpowersDir fetch --quiet origin
    git -C $superpowersDir checkout --quiet $superpowersCommit
} else {
    Write-Host "[INSTALL] Cloning official obra/superpowers and checking out tested commit $superpowersCommit..." -ForegroundColor Yellow
    git clone --quiet https://github.com/obra/superpowers.git $superpowersDir
    git -C $superpowersDir checkout --quiet $superpowersCommit
}
Write-Host "[SUCCESS] Superpowers plugin pinned to $superpowersCommit at $superpowersDir" -ForegroundColor Green

# --- 3. Apply Global Rules (GEMINI.md) ---
Write-Host "`n--- Applying Global Rules (GEMINI.md) ---" -ForegroundColor Cyan
$targetRules = Join-Path $ConfigDir "GEMINI.md"
try {
    $rulesContent = Get-Content $RulesSource -Raw -Encoding UTF8
    Set-ContentUtf8NoBom -Path $targetRules -Content $rulesContent
    Write-Host "[SUCCESS] Applied canonical rules to $targetRules (UTF-8 No-BOM)" -ForegroundColor Green
} catch {
    Write-Host "[INFO] $targetRules is protected by system boundary. Manual update may be required." -ForegroundColor Yellow
}

# --- 4. Deploy Global Skills ---
Write-Host "`n--- Deploying Global Skills ---" -ForegroundColor Cyan
$globalSkillsDir = Join-Path $ConfigDir "skills"
if ($DryRun) {
    Write-Host "[DRY-RUN] Would copy skills/* to $globalSkillsDir (UTF-8 No-BOM preserved)" -ForegroundColor Gray
} else {
    if (-not (Test-Path $SkillsSource)) {
        Write-Host "[WARN] Skills source directory not found: $SkillsSource" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path $globalSkillsDir)) {
            New-Item -ItemType Directory -Path $globalSkillsDir -Force | Out-Null
        }
        # Copy each skill subdirectory
        Get-ChildItem -Path $SkillsSource -Directory | ForEach-Object {
            $skillName = $_.Name
            $destSkillDir = Join-Path $globalSkillsDir $skillName
            if (-not (Test-Path $destSkillDir)) {
                New-Item -ItemType Directory -Path $destSkillDir -Force | Out-Null
            }
            # Copy all files in the skill dir (SKILL.md etc.)
            Get-ChildItem -Path $_.FullName -File | ForEach-Object {
                $destFile = Join-Path $destSkillDir $_.Name
                $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
                Set-ContentUtf8NoBom -Path $destFile -Content $content
            }
            Write-Host "[SUCCESS] Deployed skill '$skillName' to $destSkillDir" -ForegroundColor Green
        }
    }
}

# --- 5. Deploy Harness Hook Scripts & Merge hooks.json ---
Write-Host "`n--- Deploying Harness Hooks ---" -ForegroundColor Cyan
$globalHooksDir = Join-Path $ConfigDir "hooks"
$globalHooksJson = Join-Path $ConfigDir "hooks.json"
$hooksJsonBackup = Join-Path $ConfigDir "hooks.json.bak"

if ($DryRun) {
    Write-Host "[DRY-RUN] Would copy hooks/*.py to $globalHooksDir with absolute paths in commands" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would backup $globalHooksJson to $hooksJsonBackup" -ForegroundColor Gray
    Write-Host "[DRY-RUN] Would merge harness entries (harness-pre-tool-guard, harness-post-tool-guard, harness-stop-guard) into $globalHooksJson" -ForegroundColor Gray
    Write-Host "[DRY-RUN] All existing user/third-party hook entries preserved" -ForegroundColor Gray
} else {
    # 5a. Deploy Python scripts
    if (-not (Test-Path $HooksSource)) {
        Write-Host "[WARN] Hooks source directory not found: $HooksSource" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path $globalHooksDir)) {
            New-Item -ItemType Directory -Path $globalHooksDir -Force | Out-Null
        }
        Get-ChildItem -Path $HooksSource -Filter "*.py" | ForEach-Object {
            $destFile = Join-Path $globalHooksDir $_.Name
            $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
            Set-ContentUtf8NoBom -Path $destFile -Content $content
            Write-Host "[SUCCESS] Deployed hook script '$($_.Name)' to $destFile" -ForegroundColor Green
        }
    }

    # 5b. Merge hooks.json
    if (-not (Test-Path $HooksJsonSource)) {
        Write-Host "[WARN] Hooks JSON source not found: $HooksJsonSource" -ForegroundColor Yellow
    } else {
        try {
            Merge-HooksJson -SourcePath $HooksJsonSource -TargetPath $globalHooksJson -BackupPath $hooksJsonBackup -HooksDir $globalHooksDir
            Write-Host "[SUCCESS] hooks.json merged at $globalHooksJson (UTF-8 No-BOM)" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] hooks.json merge failed: $_" -ForegroundColor Red
        }
    }
}

# --- 6. Optional Document CLI Tools ---
if ($InstallMarkItDown) {
    Write-Host "`n--- Installing MarkItDown CLI (Recommended) ---" -ForegroundColor Cyan
    uv tool install "markitdown[all]==0.1.7" --force
    Write-Host "[SUCCESS] MarkItDown 0.1.7 installed via uv tool." -ForegroundColor Green
}

if ($InstallMinerU) {
    Write-Host "`n--- Installing MinerU Local CLI (Optional) ---" -ForegroundColor Cyan
    Write-Host "[INFO] Installing mineru[pipeline]==3.4.5 with pinned transformers 4.57.6 and six..." -ForegroundColor Yellow
    uv tool install "mineru[pipeline]==3.4.5" --with "transformers==4.57.6" --with six --force
    Write-Host "[INFO] Running MinerU compatibility test..." -ForegroundColor Yellow
    try {
        $muVer = & mineru --version 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] MinerU CLI installed: $($muVer.Trim())" -ForegroundColor Green
        } else {
            throw "Non-zero exit code: $LASTEXITCODE"
        }
    } catch {
        Write-Warning "MinerU compatibility test failed: $_"
        Write-Host "[MANUAL ACTION REQUIRED] MinerU on Windows requires environment-specific runtime compatibility." -ForegroundColor Yellow
        Write-Host "Refer to docs/TOOL-WORKFLOW.md for known Windows runtime troubleshooting." -ForegroundColor Yellow
    }
}
