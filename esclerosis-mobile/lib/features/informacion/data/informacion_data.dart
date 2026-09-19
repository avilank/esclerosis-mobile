/// Contenido educativo estatico, basado en
/// `esclerosis-movil/src/features/informacion/data/patientCopy.data.ts` y
/// `tratamientos.data.ts`. Mismo contenido para paciente y medico por ahora
/// (sin distincion de tono por rol todavia).
class IndicadorInfo {
  const IndicadorInfo({
    required this.titulo,
    required this.queEs,
    required this.porQueImporta,
    required this.accion,
  });

  final String titulo;
  final String queEs;
  final String porQueImporta;
  final String accion;
}

class TratamientoInfo {
  const TratamientoInfo({required this.grupo, required this.items, required this.nota});

  final String grupo;
  final List<String> items;
  final String nota;
}

const List<IndicadorInfo> indicadoresInfo = [
  IndicadorInfo(
    titulo: 'EDSS (gravedad)',
    queEs: 'Un número que resume qué tan afectada está tu movilidad y otras funciones.',
    porQueImporta:
        'Si sube con el tiempo, puede significar más dificultad para caminar o hacer actividades.',
    accion: 'Anota cambios en tu día a día (caminar, cansancio, equilibrio) y compártelos en tu cita.',
  ),
  IndicadorInfo(
    titulo: 'Caminar 25 pies',
    queEs: 'Mide cuánto tardas en caminar una distancia corta.',
    porQueImporta: 'Si cada vez tardas más, puede indicar que tu marcha está cambiando.',
    accion: 'Si notas tropiezos o más esfuerzo al caminar, regístralo y consulta al equipo de salud.',
  ),
  IndicadorInfo(
    titulo: 'Destreza de manos',
    queEs: 'Mide qué tan rápido y preciso se mueven tus manos (destreza fina).',
    porQueImporta: 'Si empeora, puede indicar más dificultad para tareas como abotonar o escribir.',
    accion: 'Cuenta qué tareas se te hacen más difíciles y desde cuándo.',
  ),
  IndicadorInfo(
    titulo: 'Resonancia',
    queEs: 'Una imagen del cerebro/columna para ver actividad y cambios.',
    porQueImporta: 'Ayuda a saber si hay señales de inflamación o cambios con el tiempo.',
    accion: 'Pregunta qué encontraron y si eso cambia tu plan.',
  ),
  IndicadorInfo(
    titulo: 'Atención y velocidad',
    queEs: 'Un test rápido para ver atención y velocidad de pensamiento.',
    porQueImporta: 'Cambios pueden explicar por qué te cuesta concentrarte o procesar información.',
    accion: 'Si te preocupa la memoria o concentración, dilo sin pena: es común y se puede trabajar.',
  ),
  IndicadorInfo(
    titulo: 'Fatiga',
    queEs: 'Cansancio fuerte que limita tu día, incluso sin esfuerzo grande.',
    porQueImporta: 'Es de los síntomas más comunes y se puede manejar con varias estrategias.',
    accion: 'Marca cuándo aparece, qué lo empeora y qué te ayuda.',
  ),
  IndicadorInfo(
    titulo: 'Cómo estás en lo diario',
    queEs: 'Un chequeo de cosas prácticas: caminar, manos, caídas, dolor, vejiga, etc.',
    porQueImporta: 'Sirve para ajustar tu plan a lo que realmente te afecta.',
    accion: 'Elige 1–2 metas para la próxima visita (por ejemplo: caminar más seguro o dormir mejor).',
  ),
];

const List<TratamientoInfo> tratamientosInfo = [
  TratamientoInfo(
    grupo: 'Inyectables',
    items: ['Interferones beta (IFN β-1a, β-1b, pegilado) – SC/IM', 'Acetato de glatiramero – SC'],
    nota:
        'Opción clásica en EM remitente-recurrente: perfil de seguridad conocido; útil para educación en adherencia.',
  ),
  TratamientoInfo(
    grupo: 'Orales (diarios)',
    items: [
      'Teriflunomida – oral',
      'Dimetilfumarato – oral',
      'Fingolimod – oral',
      'Ozanimod – oral',
      'Ponesimod – oral',
      'Siponimod – oral',
    ],
    nota:
        'Conveniencia y adherencia: revisar monitoreo (laboratorios, cardiaco/oftalmo según fármaco) e interacciones.',
  ),
  TratamientoInfo(
    grupo: 'Orales por ciclos',
    items: ['Cladribina – oral por ciclos'],
    nota: 'Dosis en ciclos: la experiencia del paciente suele sentirse como "tratamiento por temporadas".',
  ),
  TratamientoInfo(
    grupo: 'Infusiones / IV',
    items: ['Natalizumab – IV', 'Ocrelizumab – IV (anti-CD20)', 'Rituximab'],
    nota:
        'Alta eficacia en casos seleccionados: requiere estrategia de seguimiento (p. ej., seguridad e infecciones).',
  ),
  TratamientoInfo(
    grupo: 'IV por ciclos',
    items: ['Alemtuzumab – IV por ciclos'],
    nota: 'Regímenes en ciclos: requiere monitorización estrecha y educación intensiva del paciente.',
  ),
  TratamientoInfo(
    grupo: 'Otros',
    items: ['Mitoxantrone'],
    nota: 'Uso más excepcional: considerar riesgos/beneficios y criterios clínicos específicos.',
  ),
];
