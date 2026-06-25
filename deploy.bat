@echo off
setlocal EnableExtensions

pushd "%~dp0"

call "%~dp0get_environment_build.bat"
if errorlevel 1 (
  echo get_environment_build.bat failed.
  exit /b 1
)

set "ROOT=."
set "DIST=deploy"
set DEPLOY_ZIP=DICOM_Import_Repair_deploy.zip

rem Resolve package Python version from .python-version (single line like 3.14)
if not exist ".python-version" (
  echo Missing .python-version file.
  exit /b 1
)
set /p PY_TAG=<.python-version

rem Trim accidental spaces
for /f "tokens=* delims= " %%A in ("%PY_TAG%") do set "PY_TAG=%%A"

rem Choose runtime architecture suffix
set "ARCH_SUFFIX=-64"
if /I "%PROCESSOR_ARCHITECTURE%"=="x86" set "ARCH_SUFFIX=-32"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH_SUFFIX=-arm64"

rem Build tags from package version
set "RUNTIME_TAG=PythonEmbed/%PY_TAG%%ARCH_SUFFIX%"
set "PY_TAG_NODOT=%PY_TAG:.=%"
rem Build the expected ._pth filename from PY_TAG (3.14 -> 314)
set "PTH_FILE=%DIST%\runtime\python%PY_TAG_NODOT%._pth"

echo Using PY_TAG=%PY_TAG%
echo Using RUNTIME_TAG=%RUNTIME_TAG%
echo Using PTH_FILE=%PTH_FILE%

rem Clean old output
if exist "%DIST%" rmdir /s /q "%DIST%"
if exist "%DEPLOY_ZIP%" del /q "%DEPLOY_ZIP%"

mkdir "%DIST%" || exit /b 1

rem Copy app source and assets
copy /y "%ROOT%\*.py" "%DIST%\" >nul || exit /b 1
if exist "%DIST%\__init__.py" del /q "%DIST%\__init__.py"

copy /y "%ROOT%\LICENSE.txt" "%DIST%\" >nul || exit /b 1
copy /y "%ROOT%\README.md" "%DIST%\" >nul || exit /b 1
copy /y "%ROOT%\dicom_repair_config.toml" "%DIST%\" >nul || exit /b 1
copy /y "%ROOT%\Icons\DICOM Repair.ico" "%DIST%\" >nul || exit /b 1

mkdir "%DIST%\Documentation" || exit /b 1
robocopy "%ROOT%\Documentation" "%DIST%\Documentation" *.pdf /S /R:1 /W:1 /NFL /NDL /NJH /NJS >nul
if errorlevel 8 (
  echo Documentation copy failed.
  exit /b 1
)

rem Extract embedded Python runtime into distribution
py install "%RUNTIME_TAG%" --target="%DIST%\runtime"
if errorlevel 1 (
  echo Failed to install embedded runtime. Check Python Install Manager and tag.
  exit /b 1
)

rem Locate the runtime ._pth file and enforce isolated search paths
if not exist "%PTH_FILE%" (
  echo Could not find runtime ._pth file: %PTH_FILE%
  exit /b 1
)
> "%PTH_FILE%" (
  echo python%PY_TAG_NODOT%.zip
  echo .
  echo Lib\site-packages
  echo import site
)

rem Vendor dependencies into runtime\Lib\site-packages using build-host Python
py -%PY_TAG% -m pip install --no-compile --target "%DIST%\runtime\Lib\site-packages" -r "%ROOT%\requirements.txt"
if errorlevel 1 (
  echo Dependency vendoring failed.
  exit /b 1
)

rem Explicitly add tkinter to the installation, since it is not included in the embedded runtime by default
py -%PY_TAG% -m pip install --no-compile --target "%DIST%\runtime\Lib\site-packages" tk
if errorlevel 1 (
  echo Dependency vendoring failed.
  exit /b 1
)

rem Create portable launcher
> "%DIST%\DICOM_Repair.bat" (
  echo @echo off
  echo setlocal
  echo .\runtime\python.exe .\launch.py
)

rem Zip output
pushd "%DIST%"
"C:\Program Files\7-Zip\7z.exe" a -tzip "..\%DEPLOY_ZIP%" "." >nul
popd
if errorlevel 1 (
  echo Zip creation failed.
  exit /b 1
)

echo Portable build complete: %DEPLOY_ZIP%

popd
endlocal
exit /b 0
