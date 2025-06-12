class Aulas {
  final int? idaula;
  final int iduc;
  final int idturma;
  final DateTime data;
  final String horario;
  final String status;
  final int horas; // Adicione este campo

  Aulas({
    this.idaula,
    required this.iduc,
    required this.idturma,
    required this.data,
    required this.horario,
    required this.status,
    required this.horas, // Adicione este parâmetro
  });

  factory Aulas.fromMap(Map<String, dynamic> map) {
    return Aulas(
      idaula: map['idaula'] as int?,
      iduc: map['iduc'] as int,
      idturma: map['idturma'] as int,
      data: DateTime.parse(map['data'] as String),
      horario: map['horario'] as String,
      status: map['status'] as String,
      horas: 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idaula': idaula,
      'iduc': iduc,
      'idturma': idturma,
      'data': data.toIso8601String(),
      'horario': horario,
      'status': status,
    };
  }
}
