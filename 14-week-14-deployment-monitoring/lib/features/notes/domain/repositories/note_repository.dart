import '../../../../core/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });

  Future<Failure?> deleteNote(int id);

  Future<({int count, Failure? failure})> countDirty();

  Future<Failure?> markAllSynced();
}
