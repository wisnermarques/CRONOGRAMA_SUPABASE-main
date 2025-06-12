import 'package:cronograma/core/supabase_helper.dart';
import '../models/turma_model.dart';


class TurmaRepository {
  // Inserir turma
  Future<void> insertTurma(Turma turma) async {
    try {
      await SupabaseHelper.client.from('turma').insert(turma.toMap());
    } catch (e) {
      throw Exception('Erro ao inserir turma: $e');
    }
  }

  // Obter todas as turmas
  Future<List<Turma>> getTurmas() async {
    try {
      final response = await SupabaseHelper.client.from('turma').select();
      return (response as List).map((map) => Turma.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar turmas: $e');
    }
  }

  // Obter turmas com nomes de curso, instrutor e turno
  Future<List<Turma>> getTurmasNomes() async {
    try {
      final response = await SupabaseHelper.client
          .from('turma')
          .select('*, cursos(*), instrutores(*), turno(*)');

      // print(
      //     'Response formatado: ${const JsonEncoder.withIndent('  ').convert(response)}');

      final data = response as List<dynamic>;

      return data
          .map((map) => Turma.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar turmas com nomes: $e');
    }
  }

  // Obter turmas por curso
  Future<List<Turma>> getTurmasByCurso(int idcurso) async {
    try {
      final response = await SupabaseHelper.client
          .from('turma')
          .select()
          .eq('idcurso', idcurso);

      return (response as List).map((map) => Turma.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar turmas por curso: $e');
    }
  }

  // Obter turmas por instrutor
  Future<List<Turma>> getTurmasByInstrutor(int idinstrutor) async {
    try {
      final response = await SupabaseHelper.client
          .from('turma')
          .select()
          .eq('idinstrutor', idinstrutor);

      return (response as List).map((map) => Turma.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar turmas por instrutor: $e');
    }
  }

  // Atualizar turma
  Future<void> updateTurma(Turma turma) async {
    if (turma.idturma == null) {
      throw Exception('ID da turma não pode ser nulo.');
    }

    try {
      await SupabaseHelper.client
          .from('turma')
          .update(turma.toMap())
          .eq('idturma', turma.idturma as Object);
    } catch (e) {
      throw Exception('Erro ao atualizar turma: $e');
    }
  }

  // Deletar turma
  Future<void> deleteTurma(int id) async {
    try {
      await SupabaseHelper.client
          .from('turma')
          .delete()
          .eq('idturma', id as Object);
    } catch (e) {
      throw Exception('Erro ao deletar turma: $e');
    }
  }

  // Obter turmas com detalhes (nome do curso, instrutor, turno)
  Future<List<Map<String, dynamic>>> getTurmasComDetalhes() async {
    try {
      final response = await SupabaseHelper.client
          .from('turma')
          .select(
              '*, cursos(nomecurso), instrutores(nomeinstrutor), turno(turno)')
          .order('turma');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erro ao buscar detalhes das turmas: $e');
    }
  }
}
