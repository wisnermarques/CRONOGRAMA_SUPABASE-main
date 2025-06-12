import 'package:cronograma/core/supabase_helper.dart';
import '../models/estagio_model.dart';

class EstagioRepository {
  // Inserir um novo estágio
  Future<void> insertEstagio(Estagio estagio) async {
    try {
      await SupabaseHelper.client.from('Estagio').insert(estagio.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir estágio: $e');
    }
  }

  // Obter todos os estágios
  Future<List<Estagio>> getEstagios() async {
    try {
      final response = await SupabaseHelper.client.from('Estagio').select();
      return (response as List).map((map) => Estagio.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar estágios: $e');
    }
  }

  // Obter estágios por turma
  Future<List<Estagio>> getEstagiosPorTurma(int idturma) async {
    try {
      final response = await SupabaseHelper.client
          .from('Estagio')
          .select()
          .eq('idturma', idturma as Object);

      return (response as List).map((map) => Estagio.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar estágios por turma: $e');
    }
  }

  // Atualizar estágio
  Future<void> updateEstagio(Estagio estagio) async {
    if (estagio.idestagio == null) {
      throw Exception('ID do estágio não pode ser nulo.');
    }

    try {
      await SupabaseHelper.client
          .from('Estagio')
          .update(estagio.toMap())
          .eq('idestagio', estagio.idestagio as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar estágio: $e');
    }
  }

  // Deletar estágio
  Future<void> deleteEstagio(int id) async {
    try {
      await SupabaseHelper.client
          .from('Estagio')
          .delete()
          .eq('idestagio', id as Object);
    } catch (e) {
      throw Exception('Erro ao deletar estágio: $e');
    }
  }

  // Obter a duração total dos estágios de uma turma
  Future<int> getDuracaoTotalPorTurma(int idturma) async {
    try {
      final response = await SupabaseHelper.client.rpc(
          'soma_duracao_estagios_por_turma',
          params: {'id_turma_param': idturma});

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('Erro ao calcular duração total: $e');
    }
  }
}
