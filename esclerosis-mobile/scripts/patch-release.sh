#!/usr/bin/env bash
# Publica un parche de Shorebird (solo codigo Dart) sobre un release YA
# compilado con `shorebird release` (ver build-apk-prod.sh).
#
# Uso (desde la carpeta esclerosis-mobile):
#   ./scripts/patch-release.sh
#   ./scripts/patch-release.sh --release-version 1.2.9+29
#   ./scripts/patch-release.sh --release-version 1.2.9+29 env/prod.json
#
# Sin --release-version usa "latest": el ultimo release registrado en
# Shorebird para este app_id. Conviene pasarlo explicito cuando hubo mas de un
# release reciente y no querés depender de cual quedo ultimo.
#
# QUE PUEDE Y QUE NO PUEDE UN PARCHE
# - Si: cambios de codigo Dart (logica, textos en Dart, widgets, fixes).
# - No: dependencias nativas nuevas, cambios en android/ o ios/, assets
#   nuevos o modificados, ni cambios de version. Nada de eso viaja en el
#   parche; para eso hace falta un release nuevo.
#
# El env se pasa con --dart-define-from-file y tiene que ser EL MISMO que se
# uso al compilar el release: los valores de String.fromEnvironment quedan
# embebidos en el snapshot, asi que cambiarlos genera un binario distinto.
#
# El parche no entra en caliente: el telefono lo descarga y recien lo aplica
# al siguiente arranque de la app.

set -euo pipefail

RELEASE_VERSION="latest"
ENV_FILE="env/prod.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-version) RELEASE_VERSION="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) ENV_FILE="$1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"
# shellcheck source=_shorebird.sh
source "$SCRIPT_DIR/_shorebird.sh"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: no existe el archivo de entorno: $ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$ROOT/shorebird.yaml" ]]; then
  echo "Error: falta shorebird.yaml en la raiz del proyecto. Corre 'shorebird init' primero." >&2
  exit 1
fi

PUBSPEC_VERSION="$(grep -E '^version:' pubspec.yaml | head -n1 | sed 's/^version:[[:space:]]*//')"
SHOREBIRD_APP_ID="$(grep -E '^app_id:' shorebird.yaml | sed -E 's/^app_id:[[:space:]]*//')"

echo ">> app_id:          $SHOREBIRD_APP_ID"
echo ">> release-version: $RELEASE_VERSION"
echo ">> env:             $ENV_FILE"
echo ">> pubspec local:   $PUBSPEC_VERSION (informativo, el parche no lo usa)"
echo ""

echo ">> shorebird patch android --release-version=$RELEASE_VERSION"
run_shorebird patch android \
  --release-version="$RELEASE_VERSION" \
  --dart-define-from-file="$ENV_FILE"

echo ""
echo "OK  Parche publicado. Los telefonos con ese release lo bajan al abrir la"
echo "    app y lo aplican en el arranque siguiente."
