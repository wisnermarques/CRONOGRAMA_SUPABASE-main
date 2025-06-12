import 'package:cronograma/core/supabase_helper.dart';
import '../models/unidades_curriculares_model.dart';

class UnidadesCurricularesRepository {
  // Inserir unidade curricular
  Future<void> insertUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    try {
      await SupabaseHelper.client
          .from('unidades_curriculares')
          .insert(unidadeCurricular.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir unidade curricular: $e');
    }
  }

  // Buscar todas as unidades curriculares
  Future<List<UnidadesCurriculares>> getUnidadesCurriculares() async {
    try {
      final response =
          await SupabaseHelper.client.from('unidades_curriculares').select();

      return (response as List)
          .map((map) => UnidadesCurriculares.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar unidades curriculares: $e');
    }
  }

  // Buscar unidades curriculares por curso
  Future<List<UnidadesCurriculares>> getUnidadesByCurso(int idcurso) async {
    try {
      final response = await SupabaseHelper.client
          .from('unidades_curriculares')
          .select()
          .eq('idcurso', idcurso);

      return (response as List)
          .map((map) => UnidadesCurriculares.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar unidades por curso: $e');
    }
  }

  // Atualizar unidade curricular
  Future<void> updateUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    if (unidadeCurricular.idUc == null) {
      throw Exception('ID da unidade curricular não pode ser nulo.');
    }

    try {
      await SupabaseHelper.client
          .from('unidades_curriculares')
          .update(unidadeCurricular.toMap())
          .eq('iduc', unidadeCurricular.idUc as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar unidade curricular: $e');
    }
  }

  // Deletar unidade curricular
  Future<void> deleteUnidadeCurricular(int id) async {
    try {
      await SupabaseHelper.client
          .from('unidades_curriculares')
          .delete()
          .eq('iduc', id);
    } catch (e) {
      throw Exception('Erro ao deletar unidade curricular: $e');
    }
  }

  // Buscar unidades com nome do curso (detalhes)
  Future<List<Map<String, dynamic>>> getUnidadesComDetalhes() async {
    try {
      final response =
          await SupabaseHelper.client.rpc('get_unidades_com_detalhes');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erro ao buscar detalhes das unidades: $e');
    }
  }

  // Buscar carga horária total de um curso
  Future<int> getCargaHorariaTotalPorCurso(int idcurso) async {
    try {
      final response = await SupabaseHelper.client.rpc(
        'get_carga_total_por_curso',
        params: {'idcurso': idcurso},
      );

      return (response as int?) ?? 0;
    } catch (e) {
      throw Exception('Erro ao buscar carga horária total: $e');
    }
  }
}
