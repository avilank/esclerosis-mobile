# esclerosis_mobile

App Flutter de SclerK (migración del frontend anterior en Expo / React Native).
Consume el API REST de `esclerosis-back`. Sin servicios de Google.

## Arranque

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` apunta a `http://10.0.2.2:4027/api` (el `localhost` de la PC visto
desde el emulador Android). Para un dispositivo físico en la misma red, cambiá
esa URL por la IP LAN de la máquina que corre el backend. Ver `env/README.md`.

Antes de correr la app hay que tener el backend levantado y sembrado
(`npm run seed && npm run dev` en `esclerosis-back`).

## Verificación

```bash
flutter analyze
flutter test
```

## Build de producción

```powershell
.\scripts\build-apk-prod.ps1
```

Ver `scripts/README.md` (keystore propio, sin Google Play).

**Importante:** `env/prod.json` tiene que apuntar a una URL **https**. El
manifest de release no habilita tráfico en texto plano a propósito
(`usesCleartextTraffic` está solo en el manifest de debug, para poder hablar con
el backend local por http).

## Roles y permisos

El backend autoriza por rol (ver la tabla en `esclerosis-back/README.md`). La UI
acompaña esas reglas:

- `RoleHomeScreen` arma los tabs según `usuario.rol` (`admin`, `medico`,
  `paciente`).
- `esAdminProvider` (`features/auth/application/auth_providers.dart`) oculta las
  acciones de crear/editar/eliminar en los catálogos (tratamientos, indicadores,
  categorías), que el backend restringe a `admin`. El médico los ve en modo
  consulta.
- Los elementos marcados como `bloqueado` (los DMT y los indicadores del
  catálogo base) no muestran acciones de edición ni borrado: el asistente de
  prescripción depende de ellos.
- El rol `paciente` no pide `/recetas` (es un endpoint de personal clínico).

## Estructura

```
lib/
  app/          router + widget raíz
  core/         red (Dio + interceptor de auth), tema, storage, validación, widgets
  features/
    auth/               login, registro, sesión
    home/               dashboard por rol, perfil
    administracion/     usuarios, roles, permisos, sedes, áreas
    historia_clinica/   historias, diagnósticos, indicadores del diagnóstico, receta IA
    indicadores/        catálogo de categorías e indicadores clínicos
    tratamientos/       catálogo de DMT
    reportes/           gráficos sobre dimensiones y hechos de la API
    informacion/        contenido educativo
```

## Asistente de prescripción

`RecetaIaScreen` llama a `POST /api/ia/recetas/sugerir`, que en el backend usa
**OpenRouter**. Si `OPENROUTER_API_KEY` no está configurada, el backend responde
503 y la pantalla muestra una vista previa de ejemplo (no guarda receta).
