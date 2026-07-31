# Zentral 1-Click Installer for Windows (PowerShell)
# Automatically configures fx-autoconfig loader and installs Zentral.uc.js

$ErrorActionPreference = "Stop"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "         Zentral - 1-Click Automated Installer       " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Self-elevate to Administrator if writing to Program Files requires it
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] Requesting Administrator privileges to access Program Files..." -ForegroundColor Yellow
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit 0
    } catch {
        Write-Host "[!] Could not elevate. Attempting installation with current privileges..." -ForegroundColor Yellow
    }
}

# 1. Locate Zen Browser Application Directory
$zenAppPaths = @(
    "$env:ProgramFiles\Zen Browser",
    "$env:ProgramFiles(x86)\Zen Browser",
    "$env:LocalAppData\Programs\zen",
    "$env:LocalAppData\Zen Browser",
    "C:\Program Files\Zen Browser"
)

$zenAppDir = $null
foreach ($path in $zenAppPaths) {
    if (Test-Path "$path\zen.exe") {
        $zenAppDir = $path
        break
    }
}

if (-not $zenAppDir) {
    Write-Host "[!] Could not automatically locate Zen Browser installation directory." -ForegroundColor Yellow
    $userInput = Read-Host "Please enter full path to Zen Browser folder (e.g. C:\Program Files\Zen Browser)"
    if (Test-Path "$userInput\zen.exe") {
        $zenAppDir = $userInput
    } else {
        Write-Host "[X] Invalid Zen Browser directory. Installation aborted." -ForegroundColor Red
        exit 1
    }
}

Write-Host "[+] Found Zen Browser App Directory: $zenAppDir" -ForegroundColor Green

# 2. Locate Active Zen Profile Directory
$zenAppData = "$env:AppData\zen"
if (-not (Test-Path $zenAppData)) {
    Write-Host "[X] Could not locate Zen AppData folder at $zenAppData. Installation aborted." -ForegroundColor Red
    exit 1
}

$profilesIni = "$zenAppData\profiles.ini"
$targetProfile = $null

if (Test-Path $profilesIni) {
    $iniContent = Get-Content $profilesIni
    $isRelative = $true
    $pathVal = $null
    
    foreach ($line in $iniContent) {
        if ($line -match "^IsRelative=(.*)$") {
            $isRelative = ($Matches[1] -eq "1")
        }
        if ($line -match "^Path=(.*)$") {
            $pathVal = $Matches[1]
            if ($pathVal -like "*default*" -or $pathVal -like "*release*") {
                if ($isRelative) {
                    $targetProfile = Join-Path $zenAppData $pathVal
                } else {
                    $targetProfile = $pathVal
                }
            }
        }
    }
}

if (-not $targetProfile -or -not (Test-Path $targetProfile)) {
    $foundProfiles = Get-ChildItem "$zenAppData\Profiles" -Directory -ErrorAction SilentlyContinue
    if ($foundProfiles.Count -gt 0) {
        $targetProfile = $foundProfiles[0].FullName
    }
}

if (-not $targetProfile -or -not (Test-Path $targetProfile)) {
    Write-Host "[X] Could not locate Zen Profile directory." -ForegroundColor Red
    exit 1
}

Write-Host "[+] Found Active Zen Profile: $targetProfile" -ForegroundColor Green
Write-Host ""

# Asset Retrieval Helper (Works for both local files & web one-liner)
$repoRawUrl = "https://raw.githubusercontent.com/Michele501st/Zentral/main"
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) { $scriptRoot = Get-Location }

function Fetch-Asset {
    param([string]$relPath)
    $local = Join-Path $scriptRoot $relPath
    if (Test-Path $local) {
        return $local
    }
    $tempFile = Join-Path $env:TEMP ("zentral_" + (Split-Path $relPath -Leaf))
    $url = "$repoRawUrl/$($relPath.Replace('\', '/'))"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
        return $tempFile
    } catch {
        Write-Host "[!] Error downloading asset: $url" -ForegroundColor Red
        return $null
    }
}

# 3. Install fx-autoconfig Script Loader
Write-Host "[1/3] Installing fx-autoconfig script loader requirements..." -ForegroundColor Yellow

$configJs = Fetch-Asset "installer\app\config.js"
$configPrefs = Fetch-Asset "installer\pref\config-prefs.js"

if ($configJs) {
    Copy-Item -Path $configJs -Destination "$zenAppDir\config.js" -Force
    Write-Host "  -> Installed config.js" -ForegroundColor Gray
}

$defaultsPrefDir = Join-Path $zenAppDir "defaults\pref"
if (-not (Test-Path $defaultsPrefDir)) {
    New-Item -ItemType Directory -Path $defaultsPrefDir -Force | Out-Null
}

if ($configPrefs) {
    Copy-Item -Path $configPrefs -Destination "$defaultsPrefDir\config-prefs.js" -Force
    Write-Host "  -> Installed config-prefs.js" -ForegroundColor Gray
}

# 4. Install Chrome Engine & Zentral.uc.js
Write-Host "[2/3] Installing Chrome loader engine & Zentral script..." -ForegroundColor Yellow

$profileChrome = Join-Path $targetProfile "chrome"
$profileJS = Join-Path $profileChrome "JS"
$profileUtils = Join-Path $profileChrome "utils"

New-Item -ItemType Directory -Path $profileJS -Force | Out-Null
New-Item -ItemType Directory -Path $profileUtils -Force | Out-Null

$utilsFiles = @("boot.sys.mjs", "chrome.manifest", "fs.sys.mjs", "module_loader.mjs", "uc_api.sys.mjs", "utils.sys.mjs")
foreach ($uf in $utilsFiles) {
    $uPath = Fetch-Asset "installer\utils\$uf"
    if ($uPath) {
        Copy-Item -Path $uPath -Destination "$profileUtils\$uf" -Force
    }
}
Write-Host "  -> Installed utils/ engine files" -ForegroundColor Gray

$zentralScript = Fetch-Asset "chrome\JS\Zentral.uc.js"
if ($zentralScript) {
    Copy-Item -Path $zentralScript -Destination "$profileJS\Zentral.uc.js" -Force
    Write-Host "  -> Installed Zentral.uc.js (v1.5.0)" -ForegroundColor Gray
}

Write-Host "[3/3] Finalizing setup..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " SUCCESS! Zentral has been installed successfully.  " -ForegroundColor Green
Write-Host " Please restart Zen Browser to enjoy your new setup! " -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
