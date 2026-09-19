# Genera APK release de producción y la archiva con nombre único.
#
# Uso (desde la carpeta esclerosis-mobile):
#   .\scripts\build-apk-prod.ps1
#   .\scripts\build-apk-prod.ps1 -EnvFile env/prod.json
#   .\scripts\build-apk-prod.ps1 -SkipBump
#   .\scripts\build-apk-prod.ps1 -SkipBump -EnvFile env/prod.json
#
# Compila con `flutter build apk --release` y firma con el keystore propio
# configurado en android/key.properties (ver scripts/README.md). Sin
# Shorebird, sin OTA, sin nada de Google.
#
# Antes de compilar incrementa la version en pubspec.yaml:
#   - patch +1 con carry en 9: 1.0.9 -> 1.1.0, 1.9.9 -> 2.0.0
#   - versionCode (+N) tambien sube en 1
#
# Flutter siempre escribe/sobrescribe:
#   build\app\outputs\flutter-apk\app-release.apk
# Este script COPIA esa APK a releases\ con un nombre único:
#   esclerosis-1.0.0+1-20260710-155432-a1b2c3d.apk

param(
  [string]$EnvFile = "env/prod.json",
  [switch]$SkipBump
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path $EnvFile)) {
  Write-Error "No existe el archivo de entorno: $EnvFile"
}

function Read-AppVersionFromPubspec {
  param([string]$Content)

  if ($Content -notmatch '(?m)^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+(\d+))?') {
    Write-Error "No se pudo leer version de pubspec.yaml (formato esperado: major.minor.patch[+build])"
  }

  return @{
    Major = [int]$Matches[1]
    Minor = [int]$Matches[2]
    Patch = [int]$Matches[3]
    Code  = if ($Matches[4]) { [int]$Matches[4] } else { 0 }
  }
}

function Get-NextAppVersion {
  param(
    [int]$Major,
    [int]$Minor,
    [int]$Patch,
    [int]$Code
  )

  $Patch++
  if ($Patch -gt 9) {
    $Patch = 0
    $Minor++
    if ($Minor -gt 9) {
      $Minor = 0
      $Major++
    }
  }

  return @{
    Major = $Major
    Minor = $Minor
    Patch = $Patch
    Code  = $Code + 1
    Name  = "$Major.$Minor.$Patch"
  }
}

function Update-PubspecVersion {
  param(
    [string]$Content,
    [string]$VersionName,
    [int]$VersionCode
  )

  return [regex]::Replace(
    $Content,
    '(?m)^version:\s*.+$',
    "version: $VersionName+$VersionCode"
  )
}

$pubspecPath = Join-Path $Root "pubspec.yaml"
$pubspec = Get-Content $pubspecPath -Raw
$current = Read-AppVersionFromPubspec -Content $pubspec
$previousName = "$($current.Major).$($current.Minor).$($current.Patch)"
$previousCode = $current.Code

if ($SkipBump) {
  $versionName = $previousName
  $versionCode = $previousCode
  Write-Host ">> version (sin bump): $versionName+$versionCode"
} else {
  $next = Get-NextAppVersion @current
  $versionName = $next.Name
  $versionCode = $next.Code
  Write-Host ">> version: $previousName+$previousCode -> $versionName+$versionCode"
  $pubspec = Update-PubspecVersion -Content $pubspec -VersionName $versionName -VersionCode $versionCode
  Set-Content -Path $pubspecPath -Value $pubspec -Encoding utf8
}

Write-Host ">> flutter build apk --release --build-name=$versionName --build-number=$versionCode"
flutter build apk --release --build-name=$versionName --build-number=$versionCode --dart-define-from-file=$EnvFile
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$src = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $src)) {
  Write-Error "No se generó la APK esperada: $src"
}

$releasesDir = Join-Path $Root "releases"
New-Item -ItemType Directory -Force -Path $releasesDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$hash = (Get-FileHash -Algorithm SHA256 -Path $src).Hash.Substring(0, 8).ToLower()
$outName = "esclerosis-$versionName+$versionCode-$stamp-$hash.apk"
$dest = Join-Path $releasesDir $outName

Copy-Item -Path $src -Destination $dest -Force

$sizeMb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host ""
Write-Host "OK  Flutter output (se sobrescribe siempre):"
Write-Host "    $src"
Write-Host "OK  Copia archivada:"
Write-Host "    $dest"
Write-Host "    ($sizeMb MB)"
Write-Host ""
Write-Host "Distribui el APK de releases\ directamente (sin Google Play, sin OTA):"
Write-Host "enlace descargable, MDM propio, etc. Para publicar un cambio hay que"
Write-Host "recompilar y volver a distribuir un APK nuevo."
