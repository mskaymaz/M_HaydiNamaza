@echo off
REM ci_dogrula: CI veya yerelde Besmele yapisini tek komutla dogrular.
python Besmele\tools\validate_besmele.py
if errorlevel 1 exit /b 1
