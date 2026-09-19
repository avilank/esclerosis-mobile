import '../domain/diagnostico.dart';
import '../domain/historia_clinica.dart';
import 'diagnostico_api.dart';
import 'diagnostico_indicadores_api.dart';
import 'historia_clinica_api.dart';

/// Valor de un indicador clinico a registrar junto con un diagnostico
/// (`idIndicador` del catalogo + valor ingresado por el medico).
class IndicadorValor {
  const IndicadorValor({required this.idIndicador, required this.valor});
  final int idIndicador;
  final String valor;
}

class HistoriaClinicaRepository {
  HistoriaClinicaRepository({
    required HistoriaClinicaApi historiaClinicaApi,
    required DiagnosticoApi diagnosticoApi,
    required DiagnosticoIndicadoresApi diagnosticoIndicadoresApi,
  })  : _historiaClinicaApi = historiaClinicaApi, // ignore: prefer_initializing_formals
        _diagnosticoApi = diagnosticoApi, // ignore: prefer_initializing_formals
        _diagnosticoIndicadoresApi = diagnosticoIndicadoresApi; // ignore: prefer_initializing_formals

  final HistoriaClinicaApi _historiaClinicaApi;
  final DiagnosticoApi _diagnosticoApi;
  final DiagnosticoIndicadoresApi _diagnosticoIndicadoresApi;

  Future<HistoriaClinica?> miHistoriaClinica(int idPaciente) {
    return _historiaClinicaApi.getByPaciente(idPaciente);
  }

  Future<List<HistoriaClinica>> misPacientes(int idMedico) {
    return _historiaClinicaApi.getByMedico(idMedico);
  }

  Future<Diagnostico> diagnosticoDetalle(int idDiagnostico) {
    return _diagnosticoApi.getById(idDiagnostico);
  }

  Future<List<Diagnostico>> diagnosticosDeMedico(int idMedico) {
    return _diagnosticoApi.getByMedico(idMedico);
  }

  /// Crea un diagnostico y, si se pasan [indicadores], registra el valor de
  /// cada uno via `/diagnostico-indicadores` (ver manual de usuario
  /// ESCLEROSIS - BI, figura 37 "Registrar nuevo diagnóstico"). Los errores
  /// al guardar un indicador individual no revierten el diagnostico ya
  /// creado; se acumulan y se re-lanzan al final para que la UI pueda
  /// avisar sin perder el diagnostico.
  Future<Diagnostico> crearDiagnostico({
    required int idHistoriaClinica,
    required int idMedico,
    required DateTime fechaDiagnostico,
    required String estadoSalud,
    required String gradoEnfermedad,
    String? observaciones,
    bool esDiagnosticoInicial = false,
    List<IndicadorValor> indicadores = const [],
  }) async {
    final diagnostico = await _diagnosticoApi.create(
      idHistoriaClinica: idHistoriaClinica,
      idMedico: idMedico,
      fechaDiagnostico: fechaDiagnostico,
      estadoSalud: estadoSalud,
      gradoEnfermedad: gradoEnfermedad,
      observaciones: observaciones,
      esDiagnosticoInicial: esDiagnosticoInicial,
    );

    final errores = <String>[];
    for (final indicador in indicadores) {
      if (indicador.valor.trim().isEmpty) continue;
      try {
        await _diagnosticoIndicadoresApi.create(
          idDiagnostico: diagnostico.idDiagnostico,
          idIndicador: indicador.idIndicador,
          valor: indicador.valor.trim(),
          fechaMedicion: fechaDiagnostico,
        );
      } catch (e) {
        errores.add(e.toString());
      }
    }
    if (errores.isNotEmpty) {
      throw Exception(
        'Diagnóstico creado, pero algunos indicadores no se guardaron: ${errores.join('; ')}',
      );
    }
    return diagnostico;
  }

  Future<Diagnostico> actualizarDiagnostico(
    int id, {
    DateTime? fechaDiagnostico,
    String? estadoSalud,
    String? gradoEnfermedad,
    String? observaciones,
    bool? esDiagnosticoInicial,
  }) {
    return _diagnosticoApi.update(
      id,
      fechaDiagnostico: fechaDiagnostico,
      estadoSalud: estadoSalud,
      gradoEnfermedad: gradoEnfermedad,
      observaciones: observaciones,
      esDiagnosticoInicial: esDiagnosticoInicial,
    );
  }

  Future<void> eliminarDiagnostico(int id) {
    return _diagnosticoApi.remove(id);
  }
}
