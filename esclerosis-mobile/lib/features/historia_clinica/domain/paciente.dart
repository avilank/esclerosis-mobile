/// Mapea `esclerosis-back/src/modules/pacientes/entities/paciente.entity.ts`.
///
/// `idPaciente` es el mismo id que `idUsuario` (relacion 1:1), asi que el
/// `id` del [Usuario] logueado sirve directo como `idPaciente`.
class Paciente {
  const Paciente({
    required this.idPaciente,
    required this.dniPaciente,
    required this.nombrePaciente,
    required this.edadPaciente,
    required this.generoPaciente,
    this.direccionPaciente,
    this.telefonoPaciente,
    required this.fechaNacimiento,
  });

  final int idPaciente;
  final String dniPaciente;
  final String nombrePaciente;
  final int edadPaciente;
  final String generoPaciente;
  final String? direccionPaciente;
  final String? telefonoPaciente;
  final String fechaNacimiento;

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      idPaciente: json['idPaciente'] as int,
      dniPaciente: json['dniPaciente'] as String? ?? '',
      nombrePaciente: json['nombrePaciente'] as String? ?? '',
      edadPaciente: json['edadPaciente'] as int? ?? 0,
      generoPaciente: json['generoPaciente'] as String? ?? '',
      direccionPaciente: json['direccionPaciente'] as String?,
      telefonoPaciente: json['telefonoPaciente'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String? ?? '',
    );
  }
}
