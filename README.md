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

`test/api_integration_test.dart` prueba los clientes HTTP y el parseo de modelos
contra el backend real. Necesita `esclerosis-back` levantado en el puerto 4027
(`npm run dev`); si no responde, esos tests se saltan solos.

El `pubspec.yaml` declara `sdk: ^3.8.0`. Ojo: con esa restricción **no** se puede
usar la sintaxis `required this._campo` (private named parameters, Dart >= 3.12);
hay que asignar los campos privados en la lista de inicialización, como en
`core/network/auth_interceptor.dart`.

## Build de producción

```powershell
.\scripts\build-apk-prod.ps1
```

Ver `scripts/README.md` (keystore propio, sin Google Play).

**Importante:** `env/prod.json` tiene que apuntar a una URL **https**. El
manifest de release no habilita tráfico en texto plano a propósito
(`usesCleartextTraffic` está solo en el manifest de debug, para poder hablar con
el backend local por http).

## Citas

La secretaria agenda y el médico atiende (ver «Módulo de citas» en
`esclerosis-back/README.md`).

- Tabs por rol: **secretaria** → Citas, Pacientes, Inicio, Perfil.
  **médico** → Citas (primero), Diagnósticos, Historia Clínica, Inicio,
  Reportes, Perfil. **paciente** → Mis citas, Información, Inicio, Perfil.
  El admin abre la misma lista desde una tarjeta del dashboard.
- `features/citas/` sigue el patrón del resto: `domain/` + `data/` +
  `application/` + `presentation/`.
- `DiagnosticoFormScreen(cita: ...)` es el modo «atender»: fija historia y
  médico desde la cita y manda `idCita`. Sin cita solo entra el admin: el
  backend devuelve 403 a un médico que no adjunte `idCita`.
- La tarjeta «Diagnosticar» del dashboard del médico ahora lleva a su agenda,
  no a un formulario vacío.

## Roles y permisos

El backend autoriza por rol (ver la tabla en `esclerosis-back/README.md`). La UI
acompaña esas reglas:

- `RoleHomeScreen` arma los tabs según `usuario.rol` (`admin`, `medico`,
  `secretaria`, `paciente`). Un rol desconocido cae en un `default` mínimo, sin
  datos clínicos.
- `esPacienteProvider` es `rol == 'paciente'` (antes trataba `null` como
  paciente, lo que ocultaba funciones mientras la sesión rehidrataba). Hay
  también `esMedicoProvider`, `esSecretariaProvider` y
  `puedeGestionarCitasProvider` (admin o secretaria).
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
