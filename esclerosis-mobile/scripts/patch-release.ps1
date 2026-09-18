# Publica un parche de Shorebird (solo codigo Dart) sobre un release YA
# compilado con `shorebird release` (ver build-apk-prod.ps1).
#
# Uso (desde la carpeta esclerosis-mobile):
#   .\scripts\patch-release.ps1
#   .\scripts\patch-release.ps1 -ReleaseVersion 1.2.9+29
#   .\scripts\patch-release.ps1 -ReleaseVersion 1.2.9+29 -EnvFile env/prod.json
#
# Sin -ReleaseVersion usa "latest": el ultimo release registrado en Shorebird
# para este app_id. Conviene pasarlo explicito cuando hubo mas de un release
# reciente y no querés depender de cual quedo ultimo.
#
# QUE PUEDE Y QUE NO PUEDE UN PARCHE
# - Si: cambios de codigo Dart (logica, textos en Dart, widgets, fixes).
# - No: dependencias nativas nuevas, cambios en android\ o ios\, assets nuevos
#   o modificados, ni cambios de version. Para eso hace falta un release nuevo.
#
# Los assets NO se reempaquetan: si tocaste alguno, el CLI rechaza el patch con
# "asset diffs detected", y hace bien — instalarlo dejaria la app con assets
# viejos y codigo nuevo.
#
# El env se pasa con --dart-define-from-file y tiene que ser EL MISMO que se uso
# al compilar el release: los valores de String.fromEnvironment quedan embebidos
# en el snapshot, asi que cambiarlos genera un binario distinto.
#
# El parche no entra en caliente: el telefono lo descarga y recien lo aplica al
# siguiente arranque de la app.

param(
  [string]$ReleaseVersion = "latest",
  [string]$EnvFile = "env/prod.json"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

# Shorebird CLI: se toma de PATH salvo que se fuerce con $env:SHOREBIRD_BIN.
$Shorebird = if ($env:SHOREBIRD_BIN) { $env:SHOREBIRD_BIN } else { "shorebird" }
if (-not (Get-Command $Shorebird -ErrorAction SilentlyContinue)) {
  Write-Error "No se encontro el CLI de Shorebird ('$Shorebird'). Instalalo (ver docs.shorebird.dev) o setea `$env:SHOREBIRD_BIN."
}

if (-not (Test-Path $EnvFile)) {
  Write-Error "No existe el archivo de entorno: $EnvFile"
}

$shorebirdYaml = Join-Path $Root "shorebird.yaml"
if (-not (Test-Path $shorebirdYaml)) {
  Write-Error "Falta shorebird.yaml en la raiz del proyecto. Corre 'shorebird init' primero."
}

# A diferencia de los scripts de release, este NO toca pubspec.yaml: un parche
# no crea una version nueva, se adosa a una version ya publicada.
$pubspec = Get-Content (Join-Path $Root "pubspec.yaml") -Raw
$pubspecVersion = if ($pubspec -match '(?m)^version:\s*(.+)$') { $Matches[1].Trim() } else { "?" }
$appId = (Select-String -Path $shorebirdYaml -Pattern '^app_id:\s*(.+)$').Matches[0].Groups[1].Value.Trim()

Write-Host ">> app_id:          $appId"
Write-Host ">> release-version: $ReleaseVersion"
Write-Host ">> env:             $EnvFile"
Write-Host ">> pubspec local:   $pubspecVersion (informativo, el parche no lo usa)"
Write-Host ""

Write-Host ">> shorebird patch android --release-version=$ReleaseVersion"
& $Shorebird patch android --release-version=$ReleaseVersion --dart-define-from-file=$EnvFile
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "OK  Parche publicado. Los telefonos con ese release lo bajan al abrir la"
Write-Host "    app y lo aplican en el arranque siguiente."
