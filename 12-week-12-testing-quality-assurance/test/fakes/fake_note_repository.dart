import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note> notes = const [], this.failure})
      : notes = List.of(notes);

  /// Salinan yang bisa diubah, supaya addNote/deleteNote berefek.
  final List<Note> notes;
  final Failure? failure;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (
      notes: failure == null ? List.of(notes) : const <Note>[],
      failure: failure,
    );
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (failure != null) return (note: null, failure: failure);

    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    if (failure != null) return failure;
    notes.removeWhere((note) => note.id == id);
    return null;
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (
      count: failure == null ? notes.where((note) => note.dirty).length : 0,
      failure: failure,
    );
  }

  @override
  Future<Failure?> markAllSynced() async => failure;
}