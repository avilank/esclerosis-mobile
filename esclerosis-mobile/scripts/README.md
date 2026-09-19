# Scripts de build

Adaptados de `C:\COMUNICADOR\app-comunicador\scripts`, sin nada de Google ni
de Shorebird: no se porta `build-appbundle-prod.*` (exclusivo de Google
Play/AAB) ni `patch-release.*` (OTA de Shorebird) — cada release nuevo es un
APK completo, sin parches.

## Antes del primer build de producción

**Keystore de firma propio** (sin Google Play App Signing):

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
```

```bash
# macOS/Linux o Git Bash
./scripts/build-apk-prod.sh
./scripts/build-apk-prod.sh --skip-bump
```

El APK release queda en `build/app/outputs/flutter-apk/app-release.apk` y se
archiva con nombre único en `releases/esclerosis-<version>+<code>-<timestamp>-<hash>.apk`.
Distribuilo directo (link de descarga, MDM propio, etc.) — no hay flujo de
Google Play ni de actualizaciones OTA en este proyecto.
