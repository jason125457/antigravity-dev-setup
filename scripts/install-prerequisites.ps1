<#
.SYNOPSIS
    Verifies and installs prerequisite CLI tools.
#>
[CmdletBinding()]
param (
    [switch]$NonInteractive
)

function Test-CommandAvailable {
    param ([string]$CommandName)
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

Write-Host "=== Checking Prerequisites ===" -ForegroundColor Cyan

# 1. Git
if (Test-CommandAvailable "git") {
    $v = (git --version)
    Write-Host "[OK] Git found: $v" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Git is not installed." -ForegroundColor Yellow
    if (Test-CommandAvailable "winget") {
        Write-Host "Installing Git via winget (CurrentUser scope)..." -ForegroundColor Yellow
        winget install --id Git.Git -e --source winget --scope user --accept-source-agreements --accept-package-agreements
    } else {
        Write-Error "Please install Git manually from https://git-scm.com/ or contact IT."
    }
}

# 2. Node.js & npm / npx
if ((Test-CommandAvailable "node") -and (Test-CommandAvailable "npm") -and (Test-CommandAvailable "npx")) {
    $v = (node --version)
    Write-Host "[OK] Node.js found: $v (with npm & npx)" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Node.js is not installed." -ForegroundColor Yellow
    if (Test-CommandAvailable "winget") {
        Write-Host "Installing Node.js LTS via winget (CurrentUser scope)..." -ForegroundColor Yellow
        winget install --id OpenJS.NodeJS.LTS -e --source winget --scope user --accept-source-agreements --accept-package-agreements
    } else {
        Write-Error "Please install Node.js manually from https://nodejs.org/ or contact IT."
    }
}

# 3. uv & uvx
if ((Test-CommandAvailable "uv") -and (Test-CommandAvailable "uvx")) {
    $v = (uv --version)
    Write-Host "[OK] Astral uv found: $v" -ForegroundColor Green
} else {
    Write-Host "[MISSING] uv is not installed." -ForegroundColor Yellow
    if (Test-CommandAvailable "winget") {
        Write-Host "Installing uv via winget (CurrentUser scope)..." -ForegroundColor Yellow
        winget install --id astral-sh.uv -e --source winget --scope user --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "Installing uv via standalone user script..." -ForegroundColor Yellow
        try {
            irm https://astral.sh/uv/install.ps1 | iex
        } catch {
            Write-Warning "Failed to download uv automatically. Please download manually from https://astral.sh/uv"
        }
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

# 4. Semgrep
if (Test-CommandAvailable "semgrep") {
    $v = (semgrep --version)
    Write-Host "[OK] Semgrep found: $v" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Semgrep is not installed." -ForegroundColor Yellow
    if (Test-CommandAvailable "uv") {
        Write-Host "Installing Semgrep via uv tool (pinned to 1.177.0)..." -ForegroundColor Yellow
        uv tool install semgrep==1.177.0 --force
    } elseif (Test-CommandAvailable "pip") {
        pip install semgrep==1.177.0
    }
}

Write-Host "Prerequisites check complete." -ForegroundColor Cyan
