@echo off
:: Zentral 1-Click Installer Launcher for Windows
title Zentral Automated Installer
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause 
