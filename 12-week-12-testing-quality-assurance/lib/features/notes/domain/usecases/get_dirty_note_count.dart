import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class GetDirtyNoteCount {
  const GetDirtyNoteCount(this._repository);

  final NoteRepository _repository;

  Future<({int count, Failure? failure})> call() {
    return _repository.countDirty();
  }
}
