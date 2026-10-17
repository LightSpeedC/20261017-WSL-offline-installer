@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prepare-distro.ps1" %*
pause
