# Entornos (`--dart-define-from-file`)

Estos archivos configuran `AppEnv` (`lib/core/env/app_env.dart`) en tiempo de
compilación. No se leen en runtime: sus valores quedan embebidos en el binario.

- `dev.json`: apunta al emulador Android corriendo `esclerosis-back`
  localmente (`10.0.2.2` es el alias del `localhost` de la PC visto desde el
  emulador). Puerto `4027`, el mismo de `esclerosis-back/.env`.
- `prod.json`: reemplazar `API_BASE_URL` por el dominio real donde se
  despliegue `esclerosis-back` antes de compilar un release.

## Uso

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build apk --release --dart-define-from-file=env/prod.json
```

## Dispositivo físico en la misma red Wi-Fi

Reemplazar `10.0.2.2` por la IP LAN de la máquina que corre el backend, por
ejemplo:

```json
{ "API_BASE_URL": "http://192.168.1.51:4027/api", "ENV_NAME": "dev" }
```
