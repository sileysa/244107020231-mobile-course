import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);

  return repository.fetchNotes();
});