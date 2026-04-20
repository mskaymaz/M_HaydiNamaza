@echo off
REM pre_commit_dogrula: Commit oncesi Besmele yapisini dogrular; hata varsa commiti durdurur.
python Besmele\tools\validate_besmele.py
if errorlevel 1 exit /b 1
