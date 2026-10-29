import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int synced, Failure? failure})> call() async {
    final dirty = await _repository.countDirty();
    if (dirty.failure != null) {
      return (synced: 0, failure: dirty.failure);
    }
    if (dirty.count == 0) {
      return (synced: 0, failure: null);
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    final result = await _repository.markAllSynced();
    return (
      synced: result.failure == null ? result.count : 0,
      failure: result.failure,
    );
  }
}
