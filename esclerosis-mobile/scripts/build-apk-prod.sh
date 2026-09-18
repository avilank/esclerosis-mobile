#!/usr/bin/env bash
# Genera APK release de producción y la archiva con nombre único.
#
# Uso (desde la carpeta esclerosis-mobile):
#   ./scripts/build-apk-prod.sh
#   ./scripts/build-apk-prod.sh env/prod.json
#   ./scripts/build-apk-prod.sh --skip-bump
#   ./scripts/build-apk-prod.sh --skip-bump env/prod.json
#
# En Git Bash de Windows no uses el wrapper Unix de Shorebird: Dart recibe
# rutas POSIX y falla si MSYS_NO_PATHCONV=1. Este script lo lanza via
# shorebird.ps1. Alternativa: .\scripts\build-apk-prod.ps1 desde PowerShell.
#
# Compila con `shorebird release`, NO con `flutter build apk` a secas: ese
# binario no lleva enlazado el updater de Shorebird y el release queda huerfano
# de parches para siempre. Por eso el bump de version previo es obligatorio.
#
# Requisito previo (una sola vez): correr `shorebird init` en la raiz de este
# proyecto para generar `shorebird.yaml` con un app_id propio.
#
# Antes de compilar incrementa la version en pubspec.yaml:
#   - patch +1 con carry en 9: 1.0.9 -> 1.1.0, 1.9.9 -> 2.0.0
#   - versionCode (+N) tambien sube en 1
#
# Flutter siempre escribe/sobrescribe:
#   build/app/outputs/flutter-apk/app-release.apk
# Este script COPIA esa APK a releases/ con un nombre único:
#   esclerosis-1.0.0+1-20260710-155432-a1b2c3d.apk
#
# No genera .aab ni requiere Google Play App Signing: el firmado usa el
# keystore propio configurado en android/key.properties.

set -euo pipefail

SKIP_BUMP=0
ENV_FILE="env/prod.json"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-bump) SKIP_BUMP=1; shift ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) ENV_FILE="$1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"
# shellcheck source=_shorebird.sh
source "$SCRIPT_DIR/_shorebird.sh"

if [[ ! -f "$ROOT/shorebird.yaml" ]]; then
  echo "Error: falta shorebird.yaml en la raiz del proyecto." >&2
  echo "Corre 'shorebird init' primero (ver scripts/README.md)." >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: no existe el archivo de entorno: $ENV_FILE" >&2
  exit 1
fi

read_version_parts() {
  local line="$1"
  if [[ ! "$line" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(\+([0-9]+))?$ ]]; then
    echo "Error: no se pudo leer version de pubspec.yaml (formato esperado: major.minor.patch[+build])" >&2
    exit 1
  fi
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
  CODE="${BASH_REMATCH[5]:-0}"
}

bump_version() {
  PATCH=$((PATCH + 1))
  if (( PATCH > 9 )); then
    PATCH=0
    MINOR=$((MINOR + 1))
    if (( MINOR > 9 )); then
      MINOR=0
      MAJOR=$((MAJOR + 1))
    fi
  fi
  CODE=$((CODE + 1))
  VERSION_NAME="${MAJOR}.${MINOR}.${PATCH}"
}

update_pubspec_version() {
  local name="$1"
  local code="$2"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -E "s/^version:.*/version: ${name}+${code}/" pubspec.yaml
  else
    sed -i -E "s/^version:.*/version: ${name}+${code}/" pubspec.yaml
  fi
}

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -n1 | sed 's/^version:[[:space:]]*//')"
read_version_parts "$VERSION_LINE"

if [[ "$SKIP_BUMP" == "1" ]]; then
  VERSION_NAME="${MAJOR}.${MINOR}.${PATCH}"
  VERSION_CODE="$CODE"
  echo ">> version (sin bump): ${VERSION_NAME}+${VERSION_CODE}"
else
  PREVIOUS_NAME="${MAJOR}.${MINOR}.${PATCH}"
  PREVIOUS_CODE="$CODE"
  bump_version
  VERSION_CODE="$CODE"

  echo ">> version: ${PREVIOUS_NAME}+${PREVIOUS_CODE} -> ${VERSION_NAME}+${VERSION_CODE}"
  update_pubspec_version "$VERSION_NAME" "$VERSION_CODE"
fi

SHOREBIRD_APP_ID="$(grep -E '^app_id:' shorebird.yaml | sed -E 's/^app_id:[[:space:]]*//')"
echo ">> shorebird release android --artifact apk (app_id=$SHOREBIRD_APP_ID)"
run_shorebird release android --artifact apk --dart-define-from-file="$ENV_FILE"

SRC="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$SRC" ]]; then
  echo "Error: no se generó la APK esperada: $SRC" >&2
  exit 1
fi

mkdir -p "$ROOT/releases"

STAMP="$(date +%Y%m%d-%H%M%S)"
if command -v sha256sum >/dev/null 2>&1; then
  HASH="$(sha256sum "$SRC" | cut -c1-8)"
elif command -v shasum >/dev/null 2>&1; then
  HASH="$(shasum -a 256 "$SRC" | cut -c1-8)"
else
  HASH="$(openssl dgst -sha256 "$SRC" | awk '{print substr($NF,1,8)}')"
fi

OUT_NAME="esclerosis-${VERSION_NAME}+${VERSION_CODE}-${STAMP}-${HASH}.apk"
DEST="$ROOT/releases/$OUT_NAME"

cp -f "$SRC" "$DEST"

SIZE_MB="$(du -m "$DEST" | awk '{print $1}')"

echo ""
echo "OK  Flutter output (se sobrescribe siempre):"
echo "    $SRC"
echo "OK  Copia archivada:"
echo "    $DEST"
echo "    (${SIZE_MB} MB)"
echo ""
echo "OK  Release registrada en Shorebird para $VERSION_NAME+$VERSION_CODE."
echo ""
echo "Distribui el APK de releases/ directamente (sin Google Play)."
echo "Para parchear despues solo el codigo Dart de esa version:"
echo "    ./scripts/patch-release.sh --release-version $VERSION_NAME+$VERSION_CODE"
