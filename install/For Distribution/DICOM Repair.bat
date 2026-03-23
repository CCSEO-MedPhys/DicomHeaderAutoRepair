@echo off
set "APP_DIR=%~dp0"
cd /d "%APP_DIR%"
"%APP_DIR%\.venv\Scripts\pythonw.exe" "%APP_DIR%\dicom_repair.py"
