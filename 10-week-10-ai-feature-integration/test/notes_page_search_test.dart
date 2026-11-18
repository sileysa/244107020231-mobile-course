import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository(this._notes);
  final List<Note> _notes;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: _notes, failure: null);

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
  Future<Failure?> markAllSynced() async => null;
}

Future<void> pumpPage(WidgetTester tester, List<Note> notes) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository(notes)),
      ],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja bulanan', updatedAt: DateTime(2026)),
    Note(id: 2, title: 'Tugas Flutter', updatedAt: DateTime(2026)),
  ];

  testWidgets('query tak cocok menampilkan empty state pencarian', (
    tester,
  ) async {
    await pumpPage(tester, notes);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();

    expect(find.text('Tidak ada catatan dengan judul "xyz"'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsNothing);
  });

  testWidgets('spasi di sekitar query tidak muncul di pesan', (tester) async {
    await pumpPage(tester, notes);
    await tester.enterText(find.byType(TextField), '  xyz  ');
    await tester.pump();

    expect(find.text('Tidak ada catatan dengan judul "xyz"'), findsOneWidget);
  });

  testWidgets('query cocok hanya menampilkan catatan yang sesuai', (
    tester,
  ) async {
    await pumpPage(tester, notes);
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();

    expect(find.text('Tugas Flutter'), findsOneWidget);
    expect(find.text('Belanja bulanan'), findsNothing);
  });

  testWidgets('tombol clear mengembalikan semua catatan', (tester) async {
    await pumpPage(tester, notes);
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump();

    expect(find.text('Belanja bulanan'), findsOneWidget);
    expect(find.text('Tugas Flutter'), findsOneWidget);
  });
}
