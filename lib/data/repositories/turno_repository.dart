import 'package:cronograma/core/supabase_helper.dart';
import '../models/turno_model.dart';

class TurnoRepository {
  // Inserir turno
  Future<void> insertTurno(Turno turno) async {
    try {
      await SupabaseHelper.client.from('turno').insert(turno.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir turno: $e');
    }
  }

  // Buscar todos os turnos
  Future<List<Turno>> getTurnos() async {
    try {
      final response = await SupabaseHelper.client.from('turno').select();
      return (response as List).map((map) => Turno.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar turnos: $e');
    }
  }

  // Atualizar turno
  Future<void> updateTurno(Turno turno) async {
    if (turno.idturno == null) {
      throw Exception('ID do turno não pode ser nulo.');
    }

    try {
      await SupabaseHelper.client
          .from('turno')
          .update(turno.toMap())
          .eq('idturno', turno.idturno as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar turno: $e');
    }
  }

  // Deletar turno
  Future<void> deleteTurno(int id) async {
    try {
      await SupabaseHelper.client
          .from('turno')
          .delete()
          .eq('idturno', id as Object);
    } catch (e) {
      throw Exception('Erro ao deletar turno: $e');
    }
  }

  // Buscar ID do turno pelo nome
  Future<int?> getTurnoIdByNome(String nometurno) async {
    try {
      final response = await SupabaseHelper.client
          .from('turno')
          .select('idturno')
          .eq('turno', nometurno)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['idturno'] as int?;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar ID do turno: $e');
    }
  }

  // Verificar se turno existe pelo nome
  Future<bool> turnoExists(String nometurno) async {
    try {
      final response = await SupabaseHelper.client
          .from('turno')
          .select('idturno')
          .eq('turno', nometurno)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar existência do turno: $e');
    }
  }

  // Buscar nome do turno pelo ID
  Future<String?> getTurnoNameById(int id) async {
    try {
      final response = await SupabaseHelper.client
          .from('turno')
          .select('turno')
          .eq('idturno', id)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['turno'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar nome do turno: $e');
    }
  }
}
