class Cursos {
  final int? idcurso;
  final String nomeCurso;
  final int cargahoraria;

  const Cursos(
      {this.idcurso,
      required this.nomeCurso,
      required this.cargahoraria,
      int? idCurso});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cursos && other.idcurso == idcurso;
  }

  @override
  int get hashCode => idcurso.hashCode;
  // Factory constructor for creating from database maps
  factory Cursos.fromMap(Map<String, dynamic> map) {
    return Cursos(
        idcurso: map['idcurso'] as int?,
        nomeCurso: map['nomecurso'] as String,
        cargahoraria: map['cargahoraria'] as int);
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'nomecurso': nomeCurso,
      'cargahoraria': cargahoraria,
    };
    if (idcurso != null) {
      map['idcurso'] = idcurso;
    }

    return map;
  }

  // Format workload for display (e.g., "1200 horas")
  String get cargaHorariaFormatada => '$cargahoraria horas';

  // Categorize course by workload
  String get categoria {
    if (cargahoraria >= 1200) return 'Técnico';
    if (cargahoraria >= 400) return 'Certificação';
    return 'Curta Duração';
  }

  // Estimated duration in months (assuming 80h/month)
  int get duracaoEstimadaMeses => (cargahoraria / 80).ceil();

  // Complete course information
  String get infoCurso {
    return '''
    Curso: $nomeCurso
    Carga Horária: $cargaHorariaFormatada
    Categoria: $categoria
    Duração Estimada: $duracaoEstimadaMeses meses
    ''';
  }

  // Validate course data
  static bool validar({
    required String nome,
    required int cargahoraria,
  }) {
    return nome.length >= 5 && cargahoraria > 0;
  }

  // Helper to create short description
  String get descricaoResumida => '$nomeCurso ($categoria)';
}
