import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';
import 'package:week7_clean_architecture/main.dart';

class EmptyNoteRepository implements NoteRepository {
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (note: null, failure: null);

  @override
  Future<Failure?> deleteNote(int id) async => null;

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<({int count, Failure? failure})> markAllSynced() async =>
      (count: 0, failure: null);
}

void main() {
  testWidgets('Offline Notes app berhasil ditampilkan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(EmptyNoteRepository()),
        ],
        child: MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catatan Offline'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });
}
