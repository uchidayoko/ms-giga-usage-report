@echo off

:: .ps1を実行
start /wait powershell.exe -ExecutionPolicy Bypass -File "%~dp0reset.ps1"
pause