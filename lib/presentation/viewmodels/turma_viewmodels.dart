import '../../data/models/turma_model.dart';
import '../../data/repositories/turma_repository.dart';

class TurmaViewModel {
  final TurmaRepository repository;

  TurmaViewModel(this.repository);

  Future<void> addTurma(Turma turma) async {
    await repository.insertTurma(turma);
  }

  Future<List<Turma>> getTurmas() async {
    return await repository.getTurmas();
  }

  Future<List<Turma>> getTurmasNomes() async {
    return await repository.getTurmasNomes();
  }

  Future<void> updateTurma(Turma turma) async {
    await repository.updateTurma(turma);
  }

  Future<void> deleteTurma(int id) async {
    await repository.deleteTurma(id);
  }
}
