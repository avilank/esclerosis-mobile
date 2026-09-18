# Genera APK release de producción y la archiva con nombre único.
#
# Uso (desde la carpeta esclerosis-mobile):
#   .\scripts\build-apk-prod.ps1
#   .\scripts\build-apk-prod.ps1 -EnvFile env/prod.json
#   .\scripts\build-apk-prod.ps1 -SkipBump
#   .\scripts\build-apk-prod.ps1 -SkipBump -EnvFile env/prod.json
#
# Compila con `shorebird release`, NO con `flutter build apk` a secas: ese
# binario no lleva enlazado el updater de Shorebird y el release queda huerfano
# de parches para siempre. Por eso el bump de version previo es obligatorio:
# Shorebird no acepta registrar dos veces el mismo build-number.
#
# Requisito previo (una sola vez): correr `shorebird init` en la raiz de este
# proyecto para generar `shorebird.yaml` con un app_id propio. Sin ese archivo
# este script falla a proposito (ver chequeo abajo).
#
# Antes de compilar incrementa la version en pubspec.yaml:
#   - patch +1 con carry en 9: 1.0.9 -> 1.1.0, 1.9.9 -> 2.0.0
#   - versionCode (+N) tambien sube en 1
#
# Flutter siempre escribe/sobrescribe:
#   build\app\outputs\flutter-apk\app-release.apk
# Este script COPIA esa APK a releases\ con un nombre único:
#   esclerosis-1.0.0+1-20260710-155432-a1b2c3d.apk
#
# No genera .aab ni requiere firma de Google Play App Signing: el firmado se
# hace con el keystore propio configurado en android/key.properties
# (ver scripts/README.md).

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

# Shorebird CLI: se toma de PATH salvo que se fuerce con $env:SHOREBIRD_BIN.
$Shorebird = if ($env:SHOREBIRD_BIN) { $env:SHOREBIRD_BIN } else { "shorebird" }
if (-not (Get-Command $Shorebird -ErrorAction SilentlyContinue)) {
  Write-Error "No se encontro el CLI de Shorebird ('$Shorebird'). Instalalo (ver docs.shorebird.dev) o setea `$env:SHOREBIRD_BIN."
}

if (-not (Test-Path (Join-Path $Root "shorebird.yaml"))) {
  Write-Error "Falta shorebird.yaml en la raiz del proyecto. Corre 'shorebird init' primero (ver scripts/README.md)."
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

$appId = (Select-String -Path (Join-Path $Root "shorebird.yaml") -Pattern '^app_id:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
Write-Host ">> shorebird release android --artifact apk (app_id=$appId)"
& $Shorebird release android --artifact apk --dart-define-from-file=$EnvFile
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
Write-Host "OK  Release registrada en Shorebird para $versionName+$versionCode."
Write-Host ""
Write-Host "Distribui el APK de releases\ directamente (sin Google Play): enlace"
Write-Host "descargable, MDM propio, etc."
Write-Host "Para parchear despues solo el codigo Dart de esa version:"
Write-Host "    .\scripts\patch-release.ps1 -ReleaseVersion $versionName+$versionCode"
