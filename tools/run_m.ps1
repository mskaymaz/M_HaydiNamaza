param(
  [string]$DeviceId = "emulator-5554",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs = @()
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cacheRoot = Join-Path $repoRoot ".cache"
$androidUserHome = Join-Path $cacheRoot "android"
$localPropertiesPath = Join-Path $repoRoot "android\local.properties"

$env:GRADLE_USER_HOME = Join-Path $cacheRoot "gradle"
$env:PUB_CACHE = Join-Path $cacheRoot "pub"
$env:ANDROID_USER_HOME = $androidUserHome

New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME | Out-Null
New-Item -ItemType Directory -Force -Path $env:PUB_CACHE | Out-Null
New-Item -ItemType Directory -Force -Path $env:ANDROID_USER_HOME | Out-Null

if (Test-Path $localPropertiesPath) {
  $sdkDirLine = Get-Content $localPropertiesPath | Where-Object { $_ -like "sdk.dir=*" } | Select-Object -First 1
  if ($sdkDirLine) {
    $sdkDir = $sdkDirLine.Substring(8).Replace("\\", "\")
    $platformTools = Join-Path $sdkDir "platform-tools"
    if (Test-Path $platformTools) {
      $env:ANDROID_SDK_ROOT = $sdkDir
      $env:ANDROID_HOME = $sdkDir
      if (($env:Path -split ";") -notcontains $platformTools) {
        $env:Path = "$platformTools;$env:Path"
      }
    }
  }
}

flutter run -d $DeviceId @FlutterArgs
