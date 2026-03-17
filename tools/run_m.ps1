$ErrorActionPreference = "Stop"

param(
  [string]$DeviceId = "emulator-5554"
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cacheRoot = Join-Path $repoRoot ".cache"

$env:GRADLE_USER_HOME = Join-Path $cacheRoot "gradle"
$env:PUB_CACHE = Join-Path $cacheRoot "pub"

New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME | Out-Null
New-Item -ItemType Directory -Force -Path $env:PUB_CACHE | Out-Null

flutter run -d $DeviceId
