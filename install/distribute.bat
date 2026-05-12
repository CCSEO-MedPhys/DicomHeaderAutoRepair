rem Copy all python files except __init__.py to the "For Distribution" folder
xcopy "..\*.py" ".\For Distribution" /V /Y
del ".\For Distribution\__init__.py"

rem Build and copy the requirements.txt file to the "For Distribution" folder
pip freeze > requirements.txt
xcopy ..\requirements.txt ".\For Distribution" /V /Y\
rem Copy the virtual environment to the "For Distribution" folder
robocopy  "..\.venv" ".\For Distribution\.venv" /e /z

rem Copy additional files to the "For Distribution" folder
xcopy ..\LICENSE.txt ".\For Distribution" /V /Y
xcopy ..\README.md ".\For Distribution" /V /Y
xcopy ..\Icons\DICOM Repair.ico ".\For Distribution" /V /Y
xcopy ..\dicom_repair_config.toml ".\For Distribution" /V /Y

rem copy the Documentation folder to the "For Distribution" folder
mkdir ".\For Distribution\Documentation"
robocopy  "..\Documentation" "*.pdf" ".\For Distribution\Documentation" /e /z

rem Create a zip archive of the "For Distribution" folder using 7-Zip
"C:\Program Files\7-Zip\7z.exe" a -tzip ".\For Distribution.zip" ".\For Distribution\*"


