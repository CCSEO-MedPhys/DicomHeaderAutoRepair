@echo off
setlocal EnableExtensions

pushd "%~dp0"
if errorlevel 1 (
  echo Failed to enter script directory.
  exit /b 1
)

set "ROOT=."
set "DIST=deploy"
set "DEPLOY_ZIP=DICOM_Import_Repair_deploy.zip"
set "SEVEN_ZIP=C:\Program Files\7-Zip\7z.exe"
set "README_FILE=ReadMe.md"
set "STAGE=preflight"

rem Preflight checks
if not exist "%SEVEN_ZIP%" (
  echo Missing required tool: %SEVEN_ZIP%
  goto :fail
)
if not exist "%ROOT%\requirements.txt" (
  echo Missing requirements file: %ROOT%\requirements.txt
  goto :fail
)
if not exist "%ROOT%\dicom_repair_config.toml" (
  echo Missing config file: %ROOT%\dicom_repair_config.toml
  goto :fail
)
if not exist "%ROOT%\launch.py" (
  echo Missing launcher script: %ROOT%\launch.py
  goto :fail
)
if not exist "%ROOT%\Icons\DICOM Repair.ico" (
  echo Missing icon file: %ROOT%\Icons\DICOM Repair.ico
  goto :fail
)
if not exist "%ROOT%\ReadMe.md" (
  if exist "%ROOT%\README.md" (
    set "README_FILE=README.md"
  ) else (
    echo Missing readme file: %ROOT%\ReadMe.md or %ROOT%\README.md
    goto :fail
  )
)
if not exist "%ROOT%\LICENSE.txt" (
  echo Missing license file: %ROOT%\LICENSE.txt
  goto :fail
)

call "%~dp0get_environment_build.bat"
if errorlevel 1 (
  echo get_environment_build.bat failed.
  goto :fail
)

set "STAGE=python-version"
rem Resolve package Python version from .python-version (single line like 3.14)
if not exist ".python-version" (
  echo Missing .python-version file.
  goto :fail
)
for /f "usebackq tokens=1" %%A in (".python-version") do set "PY_TAG=%%A"
if not defined PY_TAG (
  echo .python-version is empty.
  goto :fail
)

for /f "tokens=1 delims= " %%A in ("%PY_TAG%") do set "PY_TAG=%%A"
py -%PY_TAG% --version >nul 2>&1
if errorlevel 1 (
  echo Python launcher cannot resolve version tag from .python-version: %PY_TAG%
  goto :fail
)

rem Choose runtime architecture suffix (optional arg: x64, x86, arm64)
set "ARCH_SUFFIX=-64"
if /I "%~1"=="x64" set "ARCH_SUFFIX=-64"
if /I "%~1"=="x86" set "ARCH_SUFFIX=-32"
if /I "%~1"=="arm64" set "ARCH_SUFFIX=-arm64"
if "%~1"=="" (
  if /I "%PROCESSOR_ARCHITECTURE%"=="x86" set "ARCH_SUFFIX=-32"
  if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH_SUFFIX=-arm64"
) else (
  if /I not "%~1"=="x64" if /I not "%~1"=="x86" if /I not "%~1"=="arm64" (
    echo Invalid architecture override: %~1
    echo Valid values: x64, x86, arm64
    goto :fail
  )
)

rem Build tags from package version
set "RUNTIME_TAG=PythonCore/%PY_TAG%%ARCH_SUFFIX%"
set "PY_TAG_NODOT=%PY_TAG:.=%"
rem Build the expected ._pth filename from PY_TAG (3.14 -> 314)
set "PTH_FILE=%DIST%\runtime\python%PY_TAG_NODOT%._pth"

echo Using PY_TAG=%PY_TAG%
echo Using RUNTIME_TAG=%RUNTIME_TAG%
echo Using optional PTH_FILE=%PTH_FILE%

rem Clean old output
set "STAGE=clean-output"
if exist "%DIST%" rmdir /s /q "%DIST%"
if exist "%DIST%" (
  echo Failed to remove existing output folder: %DIST%
  goto :fail
)
if exist "%DEPLOY_ZIP%" del /q "%DEPLOY_ZIP%"
if exist "%DEPLOY_ZIP%" (
  echo Failed to remove existing zip: %DEPLOY_ZIP%
  goto :fail
)

mkdir "%DIST%" || goto :fail

rem Copy app source and assets
set "STAGE=copy-assets"
copy /y "%ROOT%\*.py" "%DIST%\" >nul || goto :fail
if exist "%DIST%\__init__.py" del /q "%DIST%\__init__.py"

copy /y "%ROOT%\LICENSE.txt" "%DIST%\" >nul || goto :fail
copy /y "%ROOT%\%README_FILE%" "%DIST%\" >nul || goto :fail
copy /y "%ROOT%\dicom_repair_config.toml" "%DIST%\" >nul || goto :fail
copy /y "%ROOT%\Icons\DICOM Repair.ico" "%DIST%\" >nul || goto :fail

mkdir "%DIST%\Documentation" || goto :fail
robocopy "%ROOT%\Documentation" "%DIST%\Documentation" *.pdf /S /R:1 /W:1 /NFL /NDL /NJH /NJS >nul
if errorlevel 8 (
  echo Documentation copy failed.
  goto :fail
)

if not exist "%DIST%\launch.py" (
  echo Missing deploy artifact: %DIST%\launch.py
  goto :fail
)
if not exist "%DIST%\dicom_repair_config.toml" (
  echo Missing deploy artifact: %DIST%\dicom_repair_config.toml
  goto :fail
)
if not exist "%DIST%\DICOM Repair.ico" (
  echo Missing deploy artifact: %DIST%\DICOM Repair.ico
  goto :fail
)
if not exist "%DIST%\Documentation" (
  echo Missing deploy artifact: %DIST%\Documentation
  goto :fail
)

rem Extract embedded Python runtime into distribution
set "STAGE=install-runtime"
py install "%RUNTIME_TAG%" --target="%DIST%\runtime"
if errorlevel 1 (
  echo Failed to install embedded runtime. Check Python Install Manager and tag.
  goto :fail
)
if not exist "%DIST%\runtime\python.exe" (
  echo Embedded runtime missing executable: %DIST%\runtime\python.exe
  goto :fail
)

rem Configure runtime ._pth when present (PythonCore may not use one)
set "STAGE=configure-pth"
if exist "%PTH_FILE%" (
  > "%PTH_FILE%" (
    echo python%PY_TAG_NODOT%.zip
    echo .
    echo Lib\site-packages
    echo import site
  )
  findstr /x /c:"python%PY_TAG_NODOT%.zip" "%PTH_FILE%" >nul || goto :fail
  findstr /x /c:"." "%PTH_FILE%" >nul || goto :fail
  findstr /x /c:"Lib\site-packages" "%PTH_FILE%" >nul || goto :fail
  findstr /x /c:"import site" "%PTH_FILE%" >nul || goto :fail
) else (
  echo Runtime has no python._pth file. Using default PythonCore search paths.
)

rem Install dependencies directly into portable runtime
set "STAGE=vendor-dependencies"
"%DIST%\runtime\python.exe" -m pip install --no-compile -r "%ROOT%\requirements.txt"
if errorlevel 1 (
  echo Dependency vendoring failed.
  goto :fail
)

set "STAGE=vendor-tk"
"%DIST%\runtime\python.exe" -c "import tkinter; print(tkinter.TkVersion)" >nul 2>&1
if errorlevel 1 (
  echo Tkinter runtime verification failed.
  goto :fail
)

if not exist "%DIST%\runtime\Lib\site-packages\pydicom" (
  echo Missing vendored package: pydicom
  goto :fail
)
dir /b "%DIST%\runtime\Lib\site-packages\FreeSimpleGUI*" >nul 2>&1
if errorlevel 1 (
  echo Missing vendored package: FreeSimpleGUI
  goto :fail
)
"%DIST%\runtime\python.exe" -c "import tkinter; import pydicom; import FreeSimpleGUI" >nul 2>&1
if errorlevel 1 (
  echo Runtime import verification failed for tkinter/pydicom/FreeSimpleGUI.
  goto :fail
)

rem Create portable launcher
set "STAGE=create-launcher"
> "%DIST%\DICOM_Repair.bat" (
  echo @echo off
  echo setlocal
  echo .\runtime\python.exe .\launch.py
)
if not exist "%DIST%\DICOM_Repair.bat" (
  echo Missing deploy launcher: %DIST%\DICOM_Repair.bat
  goto :fail
)

rem Zip output
set "STAGE=zip-output"
pushd "%DIST%" || goto :fail
"%SEVEN_ZIP%" a -tzip "..\%DEPLOY_ZIP%" "." >nul
if errorlevel 1 (
  popd
  echo Zip creation failed.
  goto :fail
)
popd

if not exist "%DEPLOY_ZIP%" (
  echo Zip output not found: %DEPLOY_ZIP%
  goto :fail
)

set "STAGE=validate-zip"
"%SEVEN_ZIP%" l "%DEPLOY_ZIP%" > "%TEMP%\deploy_zip_list.txt"
if errorlevel 1 (
  echo Unable to inspect zip output.
  goto :fail
)
findstr /i /c:"DICOM_Repair.bat" "%TEMP%\deploy_zip_list.txt" >nul
if errorlevel 1 (
  echo Zip validation failed: DICOM_Repair.bat missing from archive.
  goto :fail
)
findstr /i /c:"deploy\\" "%TEMP%\deploy_zip_list.txt" >nul
if not errorlevel 1 (
  echo Zip validation failed: deploy\ folder found in archive root.
  goto :fail
)

echo Portable build complete: %DEPLOY_ZIP%

popd
endlocal
exit /b 0

:fail
echo Failed stage: %STAGE%
echo Deployment build failed.
popd
endlocal
exit /b 1
