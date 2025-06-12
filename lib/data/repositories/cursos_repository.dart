import 'package:cronograma/core/supabase_helper.dart';
import '../models/cursos_model.dart';

class CursosRepository {
  // Inserir um novo curso
  Future<void> insertCurso(Cursos curso) async {
    try {
      await SupabaseHelper.client.from('cursos').insert(curso.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir curso: $e');
    }
  }

  // Obter todos os cursos
  Future<List<Cursos>> getCursos() async {
    try {
      final response = await SupabaseHelper.client
          .from('cursos')
          .select('*')
          .order('nomecurso');
      return (response as List).map((map) => Cursos.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cursos: $e');
    }
  }

  // Atualizar curso
  Future<void> updateCurso(Cursos curso) async {
    if (curso.idcurso == null) {
      throw Exception("ID do curso não pode ser nulo.");
    }

    try {
      await SupabaseHelper.client
          .from('cursos')
          .update(curso.toMap())
          .eq('idcurso', curso.idcurso as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar curso: $e');
    }
  }

  // Deletar curso
  Future<void> deleteCurso(int id) async {
    try {
      await SupabaseHelper.client.from('cursos').delete().eq('idcurso', id);
    } catch (e) {
      throw Exception('Erro ao deletar curso: $e');
    }
  }

  // Obter ID do curso pelo nome
  Future<int?> getCursoIdByNome(String nomeCurso) async {
    try {
      final response = await SupabaseHelper.client
          .from('cursos')
          .select('idcurso')
          .eq('nomecurso', nomeCurso)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['idcurso'] as int?;
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao buscar ID do curso: $e');
    }
  }

  // Buscar cursos com carga horária mínima
  Future<List<Cursos>> getCursosPorCargaHoraria(int cargaMinima) async {
    try {
      final response = await SupabaseHelper.client
          .from('cursos')
          .select('*')
          .gte('cargahoraria', cargaMinima);

      return (response as List).map((map) => Cursos.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cursos por carga horária: $e');
    }
  }
}
