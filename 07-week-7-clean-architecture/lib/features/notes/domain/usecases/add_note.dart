import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return (
        note: null,
        failure: const ValidationFailure('Judul tidak boleh kosong'),
      );
    }
    return _repository.addNote(title: cleanTitle, body: body);
  }
}
