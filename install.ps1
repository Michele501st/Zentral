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

# 2. Locate Zen Profile Directories (Multi-Profile Support)
$zenAppData = "$env:AppData\zen"
if (-not (Test-Path $zenAppData)) {
    Write-Host "[X] Could not locate Zen AppData folder at $zenAppData. Installation aborted." -ForegroundColor Red
    exit 1
}

$profilesIni = "$zenAppData\profiles.ini"
$targetProfiles = @()

if (Test-Path $profilesIni) {
    $iniContent = Get-Content $profilesIni
    
    foreach ($line in $iniContent) {
        if ($line -match "^Path=(.*)$") {
            $pathVal = $Matches[1]
            $pPath = $null
            if ($pathVal -like "?:\*" -or $pathVal -like "\\*") {
                $pPath = $pathVal
            } else {
                $pPath = Join-Path $zenAppData $pathVal
            }
            if (Test-Path $pPath) {
                $targetProfiles += $pPath
            }
        }
    }
}

# Fallback: install to all folders in Profiles directory if profiles.ini parsing fails
if ($targetProfiles.Count -eq 0) {
    $foundProfiles = Get-ChildItem "$zenAppData\Profiles" -Directory -ErrorAction SilentlyContinue
    foreach ($fp in $foundProfiles) {
        $targetProfiles += $fp.FullName
    }
}

$targetProfiles = $targetProfiles | Select-Object -Unique

if ($targetProfiles.Count -eq 0) {
    Write-Host "[X] Could not locate any Zen Profile directories." -ForegroundColor Red
    exit 1
}

Write-Host "[+] Found active profile(s):" -ForegroundColor Green
foreach ($tp in $targetProfiles) {
    Write-Host "  -> $tp" -ForegroundColor Gray
}
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

# 3. Install fx-autoconfig Script Loader (Inlined with UTF-8 No BOM to prevent Configuration Errors)
Write-Host "[1/3] Installing fx-autoconfig script loader requirements..." -ForegroundColor Yellow

$configJsContent = @"
// skip 1st line
try {
  let cmanifest = Cc['@mozilla.org/file/directory_service;1'].getService(Ci.nsIProperties).get('UChrm', Ci.nsIFile);
  cmanifest.append('utils');
  cmanifest.append('chrome.manifest');
  if (cmanifest.exists()) {
    Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(cmanifest);
    ChromeUtils.importESModule("chrome://userchromejs/content/boot.sys.mjs");
  }
} catch (ex) {}
"@

$configPrefsContent = @"
pref("general.config.filename", "config.js");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
"@

# Write UTF-8 WITHOUT BOM (essential for Firefox autoconfig parser)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

[System.IO.File]::WriteAllText("$zenAppDir\config.js", $configJsContent, $utf8NoBom)
Write-Host "  -> Installed config.js" -ForegroundColor Gray

$defaultsPrefDir = Join-Path $zenAppDir "defaults\pref"
if (-not (Test-Path $defaultsPrefDir)) {
    New-Item -ItemType Directory -Path $defaultsPrefDir -Force | Out-Null
}

[System.IO.File]::WriteAllText("$defaultsPrefDir\config-prefs.js", $configPrefsContent, $utf8NoBom)
Write-Host "  -> Installed config-prefs.js" -ForegroundColor Gray

# 4. Install Chrome Engine & Zentral.uc.js to all profiles
Write-Host "[2/3] Installing Chrome loader engine & Zentral script to profile(s)..." -ForegroundColor Yellow

# Download assets once to temp to speed up multi-profile copying
$utilsFiles = @("boot.sys.mjs", "chrome.manifest", "fs.sys.mjs", "module_loader.mjs", "uc_api.sys.mjs", "utils.sys.mjs")
$downloadedUtils = @{}
foreach ($uf in $utilsFiles) {
    $uPath = Fetch-Asset "installer\utils\$uf"
    if ($uPath) {
        $downloadedUtils[$uf] = $uPath
    }
}
$zentralScript = Fetch-Asset "chrome\JS\Zentral.uc.js"

foreach ($targetProfile in $targetProfiles) {
    Write-Host " -> Configuring profile: $(Split-Path $targetProfile -Leaf)" -ForegroundColor Gray
    $profileChrome = Join-Path $targetProfile "chrome"
    $profileJS = Join-Path $profileChrome "JS"
    $profileUtils = Join-Path $profileChrome "utils"

    New-Item -ItemType Directory -Path $profileJS -Force | Out-Null
    New-Item -ItemType Directory -Path $profileUtils -Force | Out-Null

    foreach ($uf in $utilsFiles) {
        if ($downloadedUtils.ContainsKey($uf)) {
            Copy-Item -Path $downloadedUtils[$uf] -Destination "$profileUtils\$uf" -Force
        }
    }
    
    if ($zentralScript) {
        Copy-Item -Path $zentralScript -Destination "$profileJS\Zentral.uc.js" -Force
    }
}
Write-Host "  -> Installed Zentral.uc.js and loader engine to all profiles." -ForegroundColor Gray

Write-Host "[3/3] Finalizing setup..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " SUCCESS! Zentral has been installed successfully.  " -ForegroundColor Green
Write-Host " Please restart Zen Browser to enjoy your new setup! " -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
