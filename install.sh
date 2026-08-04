#!/usr/bin/env bash
# Zentral 1-Click Installer for macOS and Linux

set -e

echo "====================================================="
echo "         Zentral - 1-Click Automated Installer       "
echo "====================================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect OS
UNAME="$(uname -s)"
ZEN_APP_DIR=""
ZEN_PROFILE_DIR=""

if [ "$UNAME" = "Darwin" ]; then
    echo "[+] Operating System: macOS"
    ZEN_APP_DIR="/Applications/Zen Browser.app/Contents/Resources"
    ZEN_PROFILES_BASE="$HOME/Library/Application Support/zen"
elif [ "$UNAME" = "Linux" ]; then
    echo "[+] Operating System: Linux"
    ZEN_APP_DIR="/opt/zen"
    ZEN_PROFILES_BASE="$HOME/.zen"
else
    echo "[X] Unsupported OS for bash script. Please use install.ps1 on Windows."
    exit 1
fi

# Locate Profile
if [ -d "$ZEN_PROFILES_BASE" ]; then
    PROFILE_PATH=$(find "$ZEN_PROFILES_BASE" -maxdepth 2 -name "*default*" -o -name "*release*" | head -n 1)
    if [ -n "$PROFILE_PATH" ]; then
        ZEN_PROFILE_DIR="$PROFILE_PATH"
    fi
fi

if [ -z "$ZEN_PROFILE_DIR" ]; then
    echo "[X] Could not locate Zen profile directory automatically."
    read -p "Please enter path to Zen profile: " ZEN_PROFILE_DIR
fi

echo "[+] Target Profile: $ZEN_PROFILE_DIR"

# Install loader requirements
mkdir -p "$ZEN_PROFILE_DIR/chrome/JS"
mkdir -p "$ZEN_PROFILE_DIR/chrome/utils"

if [ -d "$ZEN_APP_DIR" ]; then
    cp -f "$SCRIPT_DIR/installer/app/config.js" "$ZEN_APP_DIR/" 2>/dev/null || true
    mkdir -p "$ZEN_APP_DIR/defaults/pref"
    cp -f "$SCRIPT_DIR/installer/pref/config-prefs.js" "$ZEN_APP_DIR/defaults/pref/" 2>/dev/null || true
fi

cp -rf "$SCRIPT_DIR/installer/utils/"* "$ZEN_PROFILE_DIR/chrome/utils/"
cp -f "$SCRIPT_DIR/chrome/JS/Zentral.uc.js" "$ZEN_PROFILE_DIR/chrome/JS/Zentral.uc.js"
if [ -f "$SCRIPT_DIR/chrome/userChrome.css" ]; then
    cp -f "$SCRIPT_DIR/chrome/userChrome.css" "$ZEN_PROFILE_DIR/chrome/userChrome.css"
fi

# Ensure userChrome.css is enabled in user.js
USER_JS="$ZEN_PROFILE_DIR/user.js"
PREF_LINE='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if [ -f "$USER_JS" ]; then
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS"; then
        echo "$PREF_LINE" >> "$USER_JS"
    fi
else
    echo "$PREF_LINE" > "$USER_JS"
fi

echo ""
echo "====================================================="
echo " SUCCESS! Zentral has been installed successfully.  "
echo " Please restart Zen Browser to apply changes.       "
echo "====================================================="
