class Calendarios {
  final int? idcalendarios;
  final int ano;
  final String mes;
  final String dataInicio; // Formato: 'yyyy-MM-dd'
  final String dataFim; // Formato: 'yyyy-MM-dd'
  final int idturma;

  Calendarios({
    this.idcalendarios,
    required this.ano,
    required this.mes,
    required this.dataInicio,
    required this.dataFim,
    required this.idturma,
  });

  // Adicione este factory constructor para conversão do Map para Objeto
  factory Calendarios.fromMap(Map<String, dynamic> map) {
    return Calendarios(
      idcalendarios: map['idcalendarios'] as int?,
      ano: map['ano'] as int,
      mes: map['mes'] as String,
      dataInicio: map['datainicio'] as String,
      dataFim: map['datafim'] as String,
      idturma: map['idturma'] as int,
    );
  }

  // Método para conversão do Objeto para Map
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'ano': ano,
      'mes': mes,
      'datainicio': dataInicio,
      'datafim': dataFim,
      'idturma': idturma,
    };
    if (idcalendarios != null) {
      map['idcalendarios'] = idcalendarios;
    }

    return map;
  }

  // Método opcional para formatação de datas no padrão brasileiro
  String get dataInicioFormatada {
    final date = DateTime.parse(dataInicio);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get dataFimFormatada {
    final date = DateTime.parse(dataFim);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
