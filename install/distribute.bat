xcopy ".\*.py" ".\For Distribution" /V /Y
del ".\For Distribution\__init__.py"
xcopy ..\requirements.txt ".\For Distribution" /V /Y
xcopy ..\LICENSE.txt ".\For Distribution" /V /Y
xcopy ..\README.md ".\For Distribution" /V /Y
xcopy ..\Icons\DICOM Repair.ico ".\For Distribution" /V /Y
