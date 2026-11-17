import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week7_clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

import '../test/fakes/fake_note_repository.dart';

Future<FakeNoteRepository> launchNotes(WidgetTester tester) async {
  final repo = FakeNoteRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur utama: tambah catatan lalu muncul di daftar', (
    tester,
  ) async {
    final repo = await launchNotes(tester);
    expect(find.text('Belum ada catatan'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Judul'),
      'Baca materi',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Isi'),
      'Bab testing Flutter',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Baca materi'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsNothing);
    expect(repo.notes.single.title, 'Baca materi');
  });

  testWidgets('judul kosong ditolak dengan pesan error', (tester) async {
    final repo = await launchNotes(tester);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Judul'), '   ');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
    expect(repo.notes, isEmpty);
  });

  testWidgets('alur tambah lalu cari catatan', (tester) async {
    await launchNotes(tester);

    for (final title in ['Belanja bulanan', 'Tugas Flutter']) {
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Judul'), title);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.widgetWithText(TextField, 'Cari judul catatan...'), 'flutter');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Tugas Flutter'), findsOneWidget);
    expect(find.text('Belanja bulanan'), findsNothing);
  });
}