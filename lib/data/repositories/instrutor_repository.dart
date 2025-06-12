import 'package:cronograma/core/supabase_helper.dart';
import '../models/instrutores_model.dart';

class InstrutoresRepository {
  // Inserir instrutor
  Future<void> insertInstrutor(Instrutores instrutor) async {
    try {
      await SupabaseHelper.client.from('instrutores').insert(instrutor.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir instrutor: $e');
    }
  }

  // Obter todos os instrutores
  Future<List<Instrutores>> getInstrutores() async {
    try {
      final response = await SupabaseHelper.client.from('instrutores').select();

      return (response as List).map((map) => Instrutores.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar instrutores: $e');
    }
  }

  // Atualizar instrutor
  Future<void> updateInstrutor(Instrutores instrutor) async {
    if (instrutor.idinstrutor == null) {
      throw Exception("ID do instrutor não pode ser nulo.");
    }

    try {
      await SupabaseHelper.client
          .from('instrutores')
          .update(instrutor.toMap())
          .eq('idinstrutor', instrutor.idinstrutor as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar instrutor: $e');
    }
  }

  // Deletar instrutor
  Future<void> deleteInstrutor(int id) async {
    try {
      await SupabaseHelper.client
          .from('instrutores')
          .delete()
          .eq('idinstrutor', id as Object);
    } catch (e) {
      throw Exception('Erro ao deletar instrutor: $e');
    }
  }

  // Obter ID por nome
  Future<int?> getInstrutorIdByNome(String nomeInstrutor) async {
    try {
      final response = await SupabaseHelper.client
          .from('instrutores')
          .select('idinstrutor')
          .eq('nomeinstrutor', nomeInstrutor)
          .limit(1);

      if ((response as List).isNotEmpty) {
        return response.first['idinstrutor'] as int?;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar ID do instrutor: $e');
    }
  }

  // Verificar existência por nome
  Future<bool> instrutorExists(String nomeInstrutor) async {
    try {
      final response = await SupabaseHelper.client
          .from('instrutores')
          .select('idinstrutor')
          .eq('nomeinstrutor', nomeInstrutor)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar existência do instrutor: $e');
    }
  }

  // Obter instrutores por especialização
  Future<List<Instrutores>> getInstrutoresByEspecializacao(
      String especializacao) async {
    try {
      final response = await SupabaseHelper.client
          .from('instrutores')
          .select()
          .eq('especializacao', especializacao);

      return (response as List).map((map) => Instrutores.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar por especialização: $e');
    }
  }
}
