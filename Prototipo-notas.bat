@echo off
cd /d "%~dp0"
start "" ".tools\godot\Godot_v4.7.2-stable_win64.exe" --path . res://main.tscn
