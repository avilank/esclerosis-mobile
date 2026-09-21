// Integracion real contra `esclerosis-back` corriendo en local.
//
// Verifica que los clientes HTTP y el parseo de modelos de la app siguen
// coincidiendo con la API despues de unificar la base en `clinica-bd`.
//
// Requiere el backend levantado:
//   cd ../esclerosis-back && npm run dev
//
// Si no responde, la suite se salta con un aviso (no rompe `flutter test`).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esclerosis_mobile/core/env/app_env.dart';
import 'package:esclerosis_mobile/core/network/api_exception.dart';
import 'package:esclerosis_mobile/features/auth/data/auth_api.dart';
import 'package:esclerosis_mobile/features/historia_clinica/data/diagnostico_api.dart';
import 'package:esclerosis_mobile/features/historia_clinica/data/historia_clinica_api.dart';
import 'package:esclerosis_mobile/features/historia_clinica/data/recetas_api.dart';
import 'package:esclerosis_mobile/features/indicadores/data/indicadores_api.dart';
import 'package:esclerosis_mobile/features/reportes/data/analytics_api.dart';
import 'package:esclerosis_mobile/features/tratamientos/data/tratamientos_api.dart';

const _baseUrl = 'http://127.0.0.1:4027/api';

Dio _dio({String? token}) {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl, contentType: Headers.jsonContentType));
  if (token != null) {
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      }),
    );
  }
  return dio;
}

Future<bool> _backendArriba() async {
  try {
    final socket = await Socket.connect('127.0.0.1', 4027,
        timeout: const Duration(seconds: 2));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  group('AppEnv', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('en Android usa el alias del emulador y el puerto 4027', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppEnv.apiBaseUrl, contains(':4027/api'));
      expect(AppEnv.apiBaseUrl, contains('10.0.2.2'));
    });

    test('en escritorio reescribe 10.0.2.2 a 127.0.0.1', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(AppEnv.apiBaseUrl, contains('127.0.0.1'));
      expect(AppEnv.apiBaseUrl, isNot(contains('10.0.2.2')));
    });
  });

  group('API real (esclerosis-back en :4027)', () {
    late bool disponible;
    String? tokenAdmin;
    String? tokenMedico;
    String? tokenPaciente;
    int idMedico = 0;
    int idPaciente = 0;

    setUpAll(() async {
      disponible = await _backendArriba();
      if (!disponible) {
        // ignore: avoid_print
        print('[test] backend no disponible en $_baseUrl: se saltan los tests.');
        return;
      }

      final auth = AuthApi(_dio());
      final admin = await auth.login(
          email: 'admin@esclerosis.com', password: 'password123');
      tokenAdmin = admin.token;

      final medico = await auth.login(
          email: 'dr.demo@esclerosis.com', password: 'password123');
      tokenMedico = medico.token;
      idMedico = medico.usuario.id;

      final paciente = await auth.login(
          email: 'paciente.demo@esclerosis.com', password: 'password123');
      tokenPaciente = paciente.token;
      idPaciente = paciente.usuario.id;
    });

    test('login parsea token y rol de los tres roles', () async {
      if (!disponible) return;
      final auth = AuthApi(_dio());
      for (final caso in [
        ('admin@esclerosis.com', 'admin'),
        ('dr.demo@esclerosis.com', 'medico'),
        ('paciente.demo@esclerosis.com', 'paciente'),
      ]) {
        final s = await auth.login(email: caso.$1, password: 'password123');
        expect(s.token, isNotEmpty);
        expect(s.usuario.rol, caso.$2);
        expect(s.usuario.id, greaterThan(0));
      }
    });

    test('credenciales malas -> ApiException 401', () async {
      if (!disponible) return;
      final auth = AuthApi(_dio());
      await expectLater(
        auth.login(email: 'admin@esclerosis.com', password: 'incorrecta'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('el medico lista sus historias clinicas y parsea el modelo', () async {
      if (!disponible) return;
      final api = HistoriaClinicaApi(_dio(token: tokenMedico));
      final historias = await api.getAll();
      expect(historias, isNotEmpty,
          reason: 'el seed debe crear la historia del paciente demo');
      expect(historias.first.idHistoriaClinica, greaterThan(0));
      expect(historias.first.paciente?.nombrePaciente, isNotNull);
    });

    test('el paciente obtiene SU historia clinica', () async {
      if (!disponible) return;
      final api = HistoriaClinicaApi(_dio(token: tokenPaciente));
      final historia = await api.getByPaciente(idPaciente);
      expect(historia, isNotNull);
      expect(historia!.idPaciente, idPaciente);
    });

    test('el paciente NO obtiene la de otro (403)', () async {
      if (!disponible) return;
      final api = HistoriaClinicaApi(_dio(token: tokenPaciente));
      await expectLater(
        api.getByPaciente(idPaciente + 1),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
    });

    test('stats del medico: criticos y controlados por paciente', () async {
      if (!disponible) return;
      final api = DiagnosticoApi(_dio(token: tokenMedico));
      final stats = await api.getStatsByMedico(idMedico);
      expect(stats.criticos, greaterThanOrEqualTo(0));
      expect(stats.controlados, greaterThanOrEqualTo(0));
    });

    test('catalogos: tratamientos e indicadores parsean', () async {
      if (!disponible) return;
      final tratamientos =
          await TratamientosApi(_dio(token: tokenMedico)).getAll();
      expect(tratamientos, isNotEmpty);
      expect(tratamientos.first.nombre, isNotEmpty);
      expect(tratamientos.any((t) => t.bloqueado), isTrue,
          reason: 'el catalogo DMT del seed viene bloqueado');

      final indicadores =
          await IndicadoresClinicosApi(_dio(token: tokenMedico)).getAll();
      expect(indicadores, isNotEmpty);

      final categorias =
          await CategoriasIndicadoresApi(_dio(token: tokenMedico)).getAll();
      expect(categorias, isNotEmpty);
    });

    test('el paciente NO puede listar recetas (403)', () async {
      if (!disponible) return;
      final api = RecetasApi(_dio(token: tokenPaciente));
      await expectLater(
        api.getAll(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
    });

    test('reportes: los hechos y dimensiones parsean con Fecha_Id YYYYMMDD',
        () async {
      if (!disponible) return;
      final api = AnalyticsApi(_dio(token: tokenAdmin));

      final hechosInd = await api.getHechosIndicadores();
      final dims = await api.getDimIndicadoresClinicos();
      final medicos = await api.getDimMedicos();
      final orgs = await api.getDimOrganizaciones();
      final modelos = await api.getDimModelosIa();
      final recetas = await api.getHechosRecetas();
      final em = await api.getHechosPacientesEm();
      final atendidos = await api.getHechosPacientesAtendidos();

      expect(dims, isNotEmpty);
      expect(medicos, isNotEmpty);
      expect(orgs, isNotEmpty);
      expect(modelos, isNotEmpty);

      // La pantalla de reportes filtra por fechaId asumiendo YYYYMMDD
      // (ver ReportesScreen._toFechaId).
      for (final h in hechosInd) {
        if (h.fechaId != null) {
          expect(h.fechaId.toString().length, 8,
              reason: 'fechaId debe ser YYYYMMDD');
        }
      }
      for (final h in recetas) {
        if (h.fechaId != null) {
          expect(h.fechaId.toString().length, 8);
        }
      }
      expect(em, isA<List>());
      expect(atendidos, isA<List>());
    });

    test('el paciente puede leer reportes pero no disparar el ETL', () async {
      if (!disponible) return;
      final api = AnalyticsApi(_dio(token: tokenPaciente));
      expect(await api.getHechosIndicadores(), isA<List>());

      final res = await _dio(token: tokenPaciente).post<dynamic>(
        '/analytics/etl/todo',
        options: Options(validateStatus: (_) => true),
      );
      expect(res.statusCode, 403);
    });
  });
}
