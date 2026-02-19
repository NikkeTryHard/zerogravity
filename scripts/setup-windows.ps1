# ZeroGravity — Windows setup
# Creates config directories, checks prerequisites, and downloads the release binary.
# Run as: powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1

$ErrorActionPreference = "Stop"

# ── 1. Config directory ──
Write-Host "→ Setting up config directory…"
$ConfigDir = Join-Path $env:APPDATA "zerogravity"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
Write-Host "  $ConfigDir"

# ── 2. Data directory ──
Write-Host "→ Setting up data directory…"
$DataDir = Join-Path $env:TEMP "zerogravity-standalone"
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
Write-Host "  $DataDir"

# ── 3. Prerequisite check: Antigravity must be installed ──
Write-Host "→ Checking for Antigravity installation…"
$LsBinary = Join-Path $env:LOCALAPPDATA "Programs\Antigravity\resources\app\extensions\antigravity\bin\language_server_windows_x64.exe"
if (-not (Test-Path $LsBinary)) {
    Write-Host ""
    Write-Host "✗ Antigravity is not installed (or the LS binary is missing)." -ForegroundColor Red
    Write-Host "  ZeroGravity requires a working Antigravity installation."
    Write-Host "  The Language Server binary is bundled with the Antigravity app"
    Write-Host "  and cannot be downloaded separately."
    Write-Host ""
    Write-Host "  Expected path:"
    Write-Host "    $LsBinary"
    Write-Host ""
    Write-Host "  Install Antigravity first, then re-run this script."
    Write-Host "  Alternatively, set ZEROGRAVITY_LS_PATH to a custom LS binary location."
    exit 1
}
Write-Host "  Found: $LsBinary"

# ── 4. Download prebuilt binary ──
Write-Host "→ Downloading ZeroGravity binary from GitHub Releases…"
$BinDir = Join-Path $env:LOCALAPPDATA "zerogravity\bin"
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

$GhReleaseUrl = "https://github.com/NikkeTryHard/zerogravity/releases/latest/download"
Invoke-WebRequest -Uri "$GhReleaseUrl/zerogravity-linux-x86_64" -OutFile (Join-Path $BinDir "zerogravity.exe")
Invoke-WebRequest -Uri "$GhReleaseUrl/zg-linux-x86_64" -OutFile (Join-Path $BinDir "zg.exe")

Write-Host "  Installed to: $BinDir"

# Add to PATH if not already there
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$BinDir;$CurrentPath", "User")
    Write-Host "  Added $BinDir to user PATH (restart terminal to take effect)"
}

Write-Host ""
Write-Host "✓ Setup complete."
Write-Host "  Start: zerogravity.exe"
