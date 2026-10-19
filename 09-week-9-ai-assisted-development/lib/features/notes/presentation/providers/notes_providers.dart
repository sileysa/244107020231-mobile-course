import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';

final openNotesDbProvider = Provider<Future<Database> Function()>((ref) {
  return openNotesDb;
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: ref.watch(openNotesDbProvider));
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  NoteRepository get _repository => ref.read(noteRepositoryProvider);

  @override
  Future<List<Note>> build() async {
    ref.watch(noteRepositoryProvider);
    final result = await ref.watch(getNotesProvider).call();
    if (result.failure != null) throw result.failure!;
    return result.notes;
  }

  Future<Failure?> refresh() => _reloadNotes();

  Future<Failure?> addNote({required String title, String body = ''}) async {
    final result = await _repository.addNote(title: title, body: body);
    if (result.failure != null) return result.failure;
    return _reloadNotes();
  }

  Future<Failure?> deleteNote(int id) async {
    final failure = await _repository.deleteNote(id);
    if (failure != null) return failure;
    return _reloadNotes();
  }

  Future<({int synced, Failure? failure})> syncNotes() async {
    final result = await SyncNotes(_repository).call();
    if (result.failure != null) return result;

    final refreshFailure = await _reloadNotes();
    return (synced: result.synced, failure: refreshFailure);
  }

  Future<Failure?> _reloadNotes() async {
    final result = await _repository.fetchNotes();
    if (result.failure != null) {
      state = AsyncError(result.failure!, StackTrace.current);
      return result.failure;
    }

    state = AsyncData(result.notes);
    return null;
  }
}
