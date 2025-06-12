class Estagio {
  final int? idestagio;
  final int idturma;
  final String descricao;
  final int duracao; // Duração em horas

  Estagio({
    this.idestagio,
    required this.idturma,
    required this.descricao,
    required this.duracao,
  });

  // Factory constructor para converter Map -> Estagio
  factory Estagio.fromMap(Map<String, dynamic> map) {
    return Estagio(
      idestagio: map['idestagio'] as int?,
      idturma: map['idturma'] as int,
      descricao: map['descricao'] as String,
      duracao: map['duracao'] as int,
    );
  }

  // Converte Estagio -> Map (já existente)
  Map<String, dynamic> toMap() {
    return {
      'idestagio': idestagio,
      'idturma': idturma,
      'descricao': descricao,
      'duracao': duracao,
    };
  }

  // Método útil para exibir duração formatada
  String get duracaoFormatada {
    if (duracao >= 60) {
      final horas = duracao ~/ 60;
      final minutos = duracao % 60;
      return '${horas}h ${minutos}min';
    }
    return '${duracao}min';
  }

  // Método para verificar se é um estágio longo
  bool get isEstagioLongo => duracao > 120; // Mais de 2 horas
}
