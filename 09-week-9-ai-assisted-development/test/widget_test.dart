import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';
import 'package:week7_clean_architecture/main.dart';

class EmptyNoteRepository implements NoteRepository {
  EmptyNoteRepository({this.items = const <Note>[]});

  final List<Note> items;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: items, failure: null);

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

  testWidgets('pencarian tanpa hasil menampilkan empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            EmptyNoteRepository(
              items: [
                Note(
                  title: 'Belanja Bulanan',
                  updatedAt: DateTime(2026, 10, 1),
                ),
              ],
            ),
          ),
        ],
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('notes-search-field')), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Belanja Bulanan'), findsOneWidget);
  });
}
