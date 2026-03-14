$flutterRoot = "C:\Users\MSK\dev\flutter-git"
$flutterBat = Join-Path $flutterRoot "bin\flutter.bat"

if (-not (Test-Path $flutterBat)) {
  Write-Error "Flutter bulunamadi: $flutterBat"
  Write-Host "AndroidKurulum.md dosyasindaki kurulum adimlarini izleyin."
  exit 1
}

& $flutterBat @args
