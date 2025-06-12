class UnidadesCurriculares {
  final int? idUc;
  final String nomeuc;
  final int cargahoraria; // in hours
  final int idcurso;

  UnidadesCurriculares({
    this.idUc,
    required this.nomeuc,
    required this.cargahoraria,
    required this.idcurso,
  });

  // Factory constructor to create object from Map (database result)
  factory UnidadesCurriculares.fromMap(Map<String, dynamic> map) {
    return UnidadesCurriculares(
      idUc: map['iduc'] as int?,
      nomeuc: map['nomeuc'] as String,
      cargahoraria: map['cargahoraria'] as int,
      idcurso: map['idcurso'] as int,
    );
  }

  // Convert object to Map for database operations
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'nomeuc': nomeuc,
      'cargahoraria': cargahoraria,
      'idcurso': idcurso,
    };
    if (idUc != null) {
      map['iduc'] = idUc;
    }

    return map;
  }

  // Format workload for display (e.g., "60 horas")
  String get cargaHorariaFormatada => '$cargahoraria horas';

  // Check if this is an intensive course unit
  bool get isIntensiva => cargahoraria > 60; // More than 60 hours

  // Get the estimated duration in weeks (assuming 4h/week)
  int get duracaoEstimadaSemanas => (cargahoraria / 4).ceil();

  // Helper method to display complete information
  String get infoCompleta {
    return '''
    Unidade Curricular: $nomeuc
    Carga Horária: $cargaHorariaFormatada
    Duração Estimada: $duracaoEstimadaSemanas semanas
    ${isIntensiva ? '(Curso Intensivo)' : ''}
    ''';
  }

  // Validate course unit data
  static bool validate({
    required String nomeuc,
    required int cargahoraria,
  }) {
    return nomeuc.length >= 5 && cargahoraria > 0;
  }
}
