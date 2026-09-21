# Tarea: módulo de CITAS + rol SECRETARIA (SclerK)
Implementá el módulo de citas en `c:\esclerosis\esclerosis-back` (NestJS) y `c:\esclerosis\esclerosis-mobile` (Flutter). No toques `esclerosis-movil` ni `esclerosis-app`. Respondé en español.
## Objetivo de producto
La secretaria agenda citas. Cada cita va a un paciente existente o a uno que ella acaba de dar de alta (usuario + paciente + historia clínica). El médico atiende la cita y crea el diagnóstico ligado a esa cita. Los diagnósticos actuales siguen existiendo; se les agrega `idCita` opcional.
## Restricciones
- Seguí los patrones del repo. No rediseñes auth, ni uses `permisos_rol` para guards (la auth real es `@Roles` + `RolesGuard` + `normalizeRol`).
- Fechas `date` = string `YYYY-MM-DD` (ver `src/common/utils/fecha.ts`). Nunca trates esas columnas como `Date`.
- IDs en español camelCase: `idCita`, `idPaciente`, `idMedico`. El legado `idhistoriaClinica` (c minúscula) no lo “arregles”.
- Soft-delete con `isActive`. Password con la política ya existente (8+ letras y números).
- `idPaciente` e `idMedico` = `idUsuario`. Ownership con `assertPacienteOwnsId` / `assertMedicoOwnsId`.
- Schema: editar `esclerosis-back/src/database/migrations/create_clinica_bd_schema.sql` (idempotente) Y crear la entidad TypeORM. En prod `synchronize` está off.
- UI Flutter: Riverpod 3 + GoRouter mínimo + `Navigator.push` dentro del tab. Reutilizá `CrudListScaffold`, `CrudListHeader`, `SearchField`, `StatusChip`, `InitialsAvatar`, `AppFormDialog`, `RoleHeader`, `ModuleCard`, `LoadingView`/`ErrorView`/`EmptyView`.
- No agregues HechoCitas / ETL / push / email.
## 1. Rol `secretaria`
Archivos:
- `src/common/constants/roles.constant.ts` → `ROL_SECRETARIA = 'secretaria'` y sumalo a `RolName`.
- `src/database/seeds/usuarios.seed.ts` → rol `secretaria` + usuario demo:
  - username `secretaria_demo`
  - email `secretaria.demo@esclerosis.com`
  - password `password123` (mismo hash que el resto)
  - sin ficha paciente/médico
- README backend: fila en la tabla de demos y en la matriz de autorización.
- README mobile: documentar el rol.
`UsuariosService.create` no necesita rama nueva: secretaria = usuario base, como admin. `UsuarioCreateScreen` ya soporta “otro rol” sin campos extra. El admin crea secretarias por esa pantalla cuando el rol exista en BD.
## 2. Modelo `cita`
Tabla `cita`:
- `idCita` PK identity
- `idPaciente` FK NOT NULL → paciente
- `idMedico` FK NOT NULL → medico
- `idSede` FK NULL → sede (default: sede del médico al crear)
- `fechaCita` DATE NOT NULL
- `horaCita` TIME NOT NULL  (API: string `HH:mm`; TypeORM puede hidratar `HH:mm:ss` — normalizá al devolver)
- `estado` VARCHAR NOT NULL DEFAULT `'programada'`
  Valores: `programada` | `atendida` | `cancelada` | `no_asistio`
- `motivo` TEXT NULL
- `observaciones` TEXT NULL
- `idUsuarioCreador` FK NOT NULL → usuario (secretaria o admin)
- `isActive` boolean default true
- `createdAt` / `updatedAt`
Índices: `(idMedico, fechaCita)`, `(idPaciente, fechaCita)`, `(estado, fechaCita)`.
Módulo Nest canónico: `src/modules/citas/` (entity, dto, controller, service, module). Exportar en `src/modules/index.ts` y en `src/modules/models/models.ts`.
### DTOs
`CreateCitaDto`: `idPaciente`, `idMedico`, `fechaCita` (@IsDateString), `horaCita` (regex `^([01]\d|2[0-3]):[0-5]\d$`), `idSede?`, `motivo?`, `observaciones?`.
`UpdateCitaDto`: PartialType. Cambio de fecha/hora/médico/paciente solo si `estado === 'programada'`.
Cambio de estado: `PATCH /citas/:id/estado` body `{ estado: 'cancelada' | 'no_asistio' }`. `atendida` NO se setea a mano: solo al crear el diagnóstico.
### Reglas de servicio
- Paciente y médico deben existir y `isActive`.
- Si no viene `idSede`, copiar `medico.sede.idSede`.
- `idUsuarioCreador` = `user.id` del JWT.
- Choque: 409 si existe cita `isActive` del mismo médico O del mismo paciente, misma `fechaCita`+`horaCita`, estado `programada` o `atendida`.
- Paciente sin historia activa → 400 (el alta por secretaria siempre crea historia; esto cubre data rara).
- DELETE: soft (`isActive=false` y `estado=cancelada`) si estaba `programada`.
- Transiciones: `programada` → `cancelada` | `no_asistio` | `atendida`. El resto → 409.
### API `/api/citas`
Usá `CurrentUser` + ownership. Cargá relaciones: paciente, medico (con sede), sede, creador (sin password).
| Método | Ruta | Roles | Notas |
|---|---|---|---|
| POST `/` | admin, secretaria | crea |
| GET `/` | admin, secretaria, medico, paciente | query: `fecha`, `idMedico`, `idPaciente`, `estado`. Médico: forzar `idMedico = user.id`. Paciente: forzar `idPaciente = user.id` |
| GET `/hoy` | admin, secretaria, medico | atajo `fecha=hoy` (hoy del server). Médico solo las suyas |
| GET `/:id` | mismos | paciente/médico solo la propia |
| PATCH `/:id` | admin, secretaria | editar si programada |
| PATCH `/:id/estado` | admin, secretaria, medico | médico solo `no_asistio` en citas propias programadas |
| DELETE `/:id` | admin, secretaria | soft |
Listados: devolver entidades con joins (no inventes capa Response DTO; el repo no la usa).
## 3. Lecturas que la secretaria necesita
Sin esto la UI no arranca:
- `GET /pacientes` y `GET /pacientes/:id` → `@Roles(ROL_ADMIN, ROL_SECRETARIA)`. Escritura de `PacientesController` (POST/PATCH/DELETE ficha suelta) se queda en admin. No uses ese POST para el alta con usuario.
- `GET /medicos` y `GET /medicos/:id` → sumar `ROL_SECRETARIA` al @Roles de clase; POST/PATCH/DELETE siguen admin.
- `GET /historias-clinicas` y `GET /historias-clinicas/search` → sumar `ROL_SECRETARIA` (solo lectura). POST/PATCH/DELETE de historias no para secretaria.
- `GET /sedes` → lectura para secretaria (opcional si el médico ya trae sede anidada; si `findAll` de médicos ya incluye sede, no hace falta abrir sedes). Preferí cargar `sede` en el findAll de médicos.
NO abras a secretaria: `/usuarios`, `/roles`, `/permisos`, `/recetas`, `/ia`, POST analytics, catálogos de tratamientos/indicadores en escritura.
## 4. Alta de paciente por secretaria
NO agregues `ROL_SECRETARIA` a `POST /usuarios`.
Nuevo endpoint, p.ej. `POST /api/pacientes/con-usuario`
- `@Roles(ROL_ADMIN, ROL_SECRETARIA)`
- Body = campos de paciente obligatorios del `CreateUsuarioDto` (`dniPaciente`, `nombrePaciente`, `edadPaciente`, `generoPaciente`, `fechaNacimiento`, `direccionPaciente?`, `telefonoPaciente?`) + `username`, `email`, `password`.
- Internamente reutilizá la lógica de `UsuariosService.create` forzando `idRol` del rol `paciente`. Mejor: extraé esa rama a un método transaccional (`dataSource.transaction` o QueryRunner), porque el `create` actual compensa con deletes manuales y eso es un bug conocido.
- DNI duplicado → 409. Email/username duplicado → 409.
- Respuesta: usuario con `paciente` e `historiaClinica` (o al menos `idPaciente` usable para crear la cita).
## 5. Vincular diagnóstico a cita
En SQL y entidad `Diagnostico`:
```sql
"idCita" INTEGER NULL,
CONSTRAINT "FK_diagnostico_cita" FOREIGN KEY ("idCita") REFERENCES cita ("idCita")
Índice único parcial: CREATE UNIQUE INDEX IF NOT EXISTS "UQ_diagnostico_idCita" ON diagnostico ("idCita") WHERE "idCita" IS NOT NULL;

CreateDiagnosticoDto: idCita opcional @IsInt. Flutter puede mandar también idhistoriaClinica e idMedico (siguen required en el DTO para no romper el form admin).

En DiagnosticosService.create (transacción):

Si viene idCita:
Cargar cita activa con paciente + historia.
Si estado !== 'programada' → 409.
dto.idMedico debe coincidir con cita.idMedico.
La historia del DTO debe ser la del cita.idPaciente.
Si el caller es médico: assertMedicoOwnsId sobre cita.idMedico.
Crear diagnóstico con ese idCita.
Setear cita estado = 'atendida'.
Si NO viene idCita:
Solo admin (403 si es médico). El médico no crea diagnósticos huérfanos.
Comportamiento actual (historia + médico).
Secretaria: 403 en todo /diagnosticos de escritura y en indicadores/recetas. No hace falta darle lectura de diagnósticos en v1.

Diagnostico al devolver: incluir relación cita si existe. Flutter: campo opcional idCita en Diagnostico.fromJson.

6. Tests backend
roles.constant / guards.spec.ts: secretaria pasa @Roles(ROL_SECRETARIA) y falla en endpoints admin-only.
security.integration.spec.ts:
secretaria 201 POST /citas, 201 POST /pacientes/con-usuario, 200 GET /pacientes y GET /medicos
secretaria 403 POST /usuarios, POST /diagnosticos, POST /recetas, DELETE historias
medico 403 POST /citas, 201 POST /diagnosticos con idCita de una cita suya programada
medico 403 POST /diagnosticos sin idCita
paciente 200 GET /citas propias, 403 POST /citas y GET de otro paciente
Test de servicio (unit o integration): choque de horario 409; diagnóstico marca cita atendida; segundo diagnóstico misma cita 409.
Seed: npm run seed debe poder re-ejecutarse (upsert por username/nombre de rol).
npm test verde. E2E si Postgres está.
7. Flutter (esclerosis-mobile)
Auth / home (crítico)
auth_providers.dart: esSecretariaProvider, esMedicoProvider. esPacienteProvider debe ser solo rol == 'paciente' (hoy trata null como paciente; no lo uses para ocultar citas).
role_home_screen.dart: case 'secretaria': obligatorio. Si no, ve tabs de paciente.
Tabs secretaria (5):

Citas
Pacientes
Inicio
Perfil
(quinto) no pongas Reportes. Si necesitás 5, repetí el patrón admin y dejá Perfil + un tab de apoyo; preferible 4 tabs fijos: Citas, Pacientes, Inicio, Perfil. BottomNavigationBarType.fixed ya está.
Tabs médico: insertar Citas como primer tab. Dejar Diagnósticos, Historia Clínica, Inicio, Reportes, Perfil (6 tabs, type: fixed).

Admin: no hace falta tab nuevo. En DashboardScreen agregar ModuleCard “Citas” que abre la misma lista (sin filtro de médico).

Dashboard secretaria: RoleHeader con stats del día (programadas / atendidas / canceladas) vía GET /citas/hoy. Cards: Citas, Pacientes.

Dashboard médico: card “Citas de hoy”. Quitar o redirigir “Diagnosticar”: debe ir a citas programadas, no a DiagnosticoFormScreen() vacío.

Feature lib/features/citas/
Espejo de historia_clinica / administracion:

domain/cita.dart + fromJson (paciente, medico, sede, estado, fechaCita, horaCita)
data/citas_api.dart (Dio, mismo estilo que DiagnosticoApi)
application/citas_providers.dart
presentation/citas_list_screen.dart — lista + buscador local + chips de estado + filtro fecha (default hoy). FAB crear solo secretaria/admin.
presentation/cita_form_screen.dart — paciente (búsqueda por DNI/nombre sobre lista de pacientes), médico, fecha, hora (dropdown 08:00–18:00 cada 30 min está bien; el API acepta cualquier HH:mm), motivo, observaciones. Si el paciente no existe: botón “Crear paciente” → pantalla de alta → vuelve con el paciente seleccionado.
presentation/cita_detalle_screen.dart — datos + acciones según rol:
secretaria/admin: editar si programada, cancelar, marcar no asistió
médico: “Atender” (si programada y propia) → DiagnosticoFormScreen con la cita; “No asistió”
paciente: solo lectura
StatusChip por estado (colores del theme teal; cancelada/no_asistio en gris/rojo suave).
Alta de paciente
Nueva pantalla (o extraé el bloque paciente de usuario_create_screen.dart): mismos campos (DNI 8, teléfono 9, fecha nacimiento, género, password policy). POST a /pacientes/con-usuario. Tab Pacientes de secretaria: lista GET /pacientes + FAB.

Diagnóstico desde cita
DiagnosticoFormScreen({ this.cita }):

Si cita != null: bloquear historia y médico; prellenar fecha con cita.fechaCita; al POST mandar idCita, idMedico, idhistoriaClinica (resolver historia del paciente; si el GET de cita no la trae, pedí GET /historias-clinicas/paciente/:id).
Si cita == null: solo admin. Médico no entra por acá.
Tras éxito: el flujo receta IA actual se mantiene. Invalidar providers de citas y de diagnósticos.

Modelo Diagnostico: idCita opcional. En listas, un chip “Con cita” / “Sin cita” es suficiente; no hace falta rediseñar la lista.

Tests Flutter
flutter analyze limpio.
Extender test/api_integration_test.dart (se salta si el back no está): login secretaria.demo@esclerosis.com / password123; GET citas; 403 diagnósticos POST; crear paciente+cita si el back está seeded.
Widget smoke no es obligatorio más allá de no romper widget_test.dart.
8. Orden de implementación
Constante + seed + SQL + entidad Cita
Módulo citas (API + reglas + tests de guard)
idCita en diagnóstico + transacción atendida
Endpoint POST /pacientes/con-usuario + abrir GETs
Flutter auth/tabs/providers
Feature citas + alta paciente
Enganchar DiagnosticoFormScreen
README + seed demo + analyze/test
9. Definition of done
Login secretaria_demo muestra Citas/Pacientes, no la home de paciente.
Secretaria crea paciente nuevo, agenda cita con dr_demo, la ve en la lista.
Secretaria agenda cita con paciente_demo existente.
Choque mismo médico+fecha+hora → error visible (409).
dr_demo ve la cita, pulsa Atender, completa diagnóstico+indicadores; la cita pasa a atendida; no puede diagnosticar de nuevo esa cita.
dr_demo no puede crear diagnóstico sin cita (403).
Admin sigue creando diagnóstico sin cita.
Diagnósticos anteriores se listan igual, con idCita null.
Paciente ve solo sus citas.
Secretaria no entra a usuarios/roles/recetas/IA.
npm test y flutter analyze OK.
10. No hagas
No implementes confirmación por WhatsApp/email, slots de duración, calendario week-view, ni secretaria atada a una sede.
No migres Expo (esclerosis-movil).
No cambies el casing idhistoriaClinica.
No pongas DB_SYNCHRONIZE=true en prod.
No dejes el case de secretaria en el default de _tabsFor.
---
Con esto otro agente puede implementar sin reabrir el diseño. Lo único que dejaría para un comentario tuyo, si te molesta, es el **tab extra del médico** (Citas como primer tab, 6 en total) y que el médico **ya no** pueda diagnosticar sin cita. El resto está cerrado a propósito para no volver a negociar el modelo a mitad de código.
