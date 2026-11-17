import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int syncedCount, Failure? failure})> call() async {
    final dirtyResult = await _repository.countDirty();
    if (dirtyResult.failure != null) {
      return (syncedCount: 0, failure: dirtyResult.failure);
    }

    if (dirtyResult.count == 0) {
      return (syncedCount: 0, failure: null);
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    final failure = await _repository.markAllSynced();
    return (
      syncedCount: failure == null ? dirtyResult.count : 0,
      failure: failure,
    );
  }
}
