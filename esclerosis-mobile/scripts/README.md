# Scripts de build

Adaptados de `C:\COMUNICADOR\app-comunicador\scripts`, sin nada de Google:
no se porta `build-appbundle-prod.*` (exclusivo de Google Play/AAB) y no hay
ningún paso de Firebase.

## Antes del primer build de producción

1. **Shorebird** (OTA de código Dart, no es de Google):
   ```bash
   dart pub global activate shorebird_code_push # o instalar el CLI, ver docs.shorebird.dev
   shorebird init
   ```
   Esto crea `shorebird.yaml` con un `app_id` propio en la raíz del proyecto.
   Sin ese archivo, `build-apk-prod.*` falla a propósito (evita publicar un
   binario sin el updater enlazado).

2. **Keystore de firma propio** (sin Google Play App Signing):
   ```powershell
   keytool -genkeypair -v -keystore android/esclerosis-release.jks `
     -keyalg RSA -keysize 2048 -validity 10000 -alias esclerosis
   ```
   y completar `android/key.properties` (ver plantilla en ese archivo).

## Uso

```powershell
# Windows / PowerShell
.\scripts\build-apk-prod.ps1                      # bump de version + compila
.\scripts\build-apk-prod.ps1 -SkipBump             # reintento sin bump
.\scripts\patch-release.ps1 -ReleaseVersion 1.0.1+2  # parche OTA de solo Dart
```

```bash
# macOS/Linux o Git Bash
./scripts/build-apk-prod.sh
./scripts/build-apk-prod.sh --skip-bump
./scripts/patch-release.sh --release-version 1.0.1+2
```

El APK release queda en `build/app/outputs/flutter-apk/app-release.apk` y se
archiva con nombre único en `releases/esclerosis-<version>+<code>-<timestamp>-<hash>.apk`.
Distribuilo directo (link de descarga, MDM propio, etc.) — no hay flujo de
Google Play en este proyecto.
