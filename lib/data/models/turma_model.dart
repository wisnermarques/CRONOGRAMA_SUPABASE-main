import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/models/turno_model.dart';

class Turma {
  final int? idturma;
  final String turmanome;
  final int? idcurso;
  final int idturno;
  final int idinstrutor;
  final Cursos? cursos;
  final Instrutores? instrutores;
  final Turno? turno;

  Turma({
    this.idturma,
    required this.turmanome,
    this.idcurso,
    required this.idturno,
    required this.idinstrutor,
    this.cursos,
    this.instrutores,
    this.turno,
  });

  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      idturma: safeParseInt(map['idturma']),
      turmanome: map['turmanome']?.toString().trim() ?? '[Sem nome]',
      idcurso: safeParseInt(map['idcurso']),
      idturno: safeParseInt(map['idturno']) ?? 1, // Valor padrão 1
      idinstrutor: safeParseInt(map['idinstrutor']) ?? 0,
      cursos: map['cursos'] != null ? Cursos.fromMap(map['cursos']) : null,
      instrutores: map['instrutores'] != null
          ? Instrutores.fromMap(map['instrutores'])
          : null,
      turno: map['turno'] != null ? Turno.fromMap(map['turno']) : null,
    );
  }

  static int? safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'turmanome': turmanome,
      'idcurso': idcurso,
      'idturno': idturno,
      'idinstrutor': idinstrutor,
    };
    if (idturma != null) {
      map['idturma'] = idturma;
    }

    return map;
  }
}
