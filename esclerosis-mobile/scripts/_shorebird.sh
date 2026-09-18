# Sourced por los scripts de release/parche. No ejecutar directo.
# En Git Bash de Windows el wrapper Unix de Shorebird pasa rutas POSIX a
# dart.exe. Si MSYS_NO_PATHCONV=1 o MSYS2_ARG_CONV_EXCL=* (habitual en Windows),
# Dart no encuentra shorebird.snapshot y falla con:
#   Could not find a command named ".../shorebird.snapshot"
# En ese entorno hay que lanzar shorebird.ps1 via powershell.exe con rutas Windows.

_is_windows_bash() {
  [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == mingw* || "${OSTYPE:-}" == cygwin* || -n "${MSYSTEM:-}" ]]
}

_to_win_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

_resolve_shorebird_bin() {
  if [[ -n "${SHOREBIRD_BIN:-}" ]]; then
    return 0
  fi
  if _is_windows_bash && [[ -f "$HOME/.shorebird/bin/shorebird.ps1" ]]; then
    SHOREBIRD_BIN="$HOME/.shorebird/bin/shorebird.ps1"
    return 0
  fi
  if command -v shorebird >/dev/null 2>&1; then
    SHOREBIRD_BIN="$(command -v shorebird)"
  else
    SHOREBIRD_BIN="$HOME/.shorebird/bin/shorebird"
  fi
}

_windows_shorebird_ps1() {
  local candidate="${1:-}"
  if [[ "$candidate" == *.ps1 && -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  if [[ -n "$candidate" && -f "${candidate}.ps1" ]]; then
    printf '%s\n' "${candidate}.ps1"
    return 0
  fi
  if [[ -n "$candidate" && -f "${candidate%/*}/shorebird.ps1" ]]; then
    printf '%s\n' "${candidate%/*}/shorebird.ps1"
    return 0
  fi
  if [[ -f "$HOME/.shorebird/bin/shorebird.ps1" ]]; then
    printf '%s\n' "$HOME/.shorebird/bin/shorebird.ps1"
    return 0
  fi
  return 1
}

_ps_quote() {
  local s="$1"
  s="${s//\'/\'\'}"
  printf "'%s'" "$s"
}

run_shorebird() {
  _resolve_shorebird_bin

  if _is_windows_bash; then
    local ps1
    if ! ps1="$(_windows_shorebird_ps1 "$SHOREBIRD_BIN")"; then
      echo "Error: no se encontro shorebird.ps1 (instalacion de Shorebird en Windows)." >&2
      echo "Instalalo (ver docs.shorebird.dev) o exporta SHOREBIRD_BIN." >&2
      return 1
    fi

    local -a converted=()
    local arg val
    for arg in "$@"; do
      if [[ "$arg" == --dart-define-from-file=* ]]; then
        val="${arg#--dart-define-from-file=}"
        converted+=("--dart-define-from-file=$(_to_win_path "$val")")
      else
        converted+=("$arg")
      fi
    done

    local ps1_win
    ps1_win="$(_to_win_path "$ps1")"
    local ps_args=""
    for arg in "${converted[@]}"; do
      ps_args+=" $(_ps_quote "$arg")"
    done

    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
      "& { & $(_ps_quote "$ps1_win")${ps_args}; exit \$LASTEXITCODE }"
    return $?
  fi

  if [[ ! -x "$SHOREBIRD_BIN" ]]; then
    echo "Error: no se encontro el CLI de Shorebird en $SHOREBIRD_BIN" >&2
    echo "Instalalo (ver docs.shorebird.dev) o exporta SHOREBIRD_BIN con la ruta." >&2
    return 1
  fi
  "$SHOREBIRD_BIN" "$@"
}
