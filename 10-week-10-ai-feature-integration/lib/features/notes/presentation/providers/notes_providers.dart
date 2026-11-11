import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/notes_database.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_dirty_note_count.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/usecases/search_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  return DeleteNote(ref.watch(noteRepositoryProvider));
});

final getDirtyNoteCountProvider = Provider<GetDirtyNoteCount>((ref) {
  return GetDirtyNoteCount(ref.watch(noteRepositoryProvider));
});

final syncNotesProvider = Provider<SyncNotes>((ref) {
  return SyncNotes(ref.watch(noteRepositoryProvider));
});

final searchNotesProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

final notesProvider = FutureProvider<({List<Note> notes, Failure? failure})>((
  ref,
) {
  return ref.watch(getNotesProvider).call();
});

final dirtyCountProvider = FutureProvider<({int count, Failure? failure})>(
  (ref) => ref.watch(getDirtyNoteCountProvider).call(),
);
