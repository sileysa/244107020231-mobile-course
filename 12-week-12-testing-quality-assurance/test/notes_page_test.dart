import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

import 'fakes/fake_note_repository.dart';

Future<void> pumpPage(WidgetTester tester, FakeNoteRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final seed = [
    Note(id: 1, title: 'Belanja bulanan', updatedAt: DateTime(2026)),
    Note(id: 2, title: 'Tugas Flutter', updatedAt: DateTime(2026)),
  ];

  group('NotesPage - tampilan awal', () {
    testWidgets('menampilkan keadaan kosong', (tester) async {
      await pumpPage(tester, FakeNoteRepository());

      expect(find.text('Catatan Offline'), findsOneWidget);
      expect(find.text('Belum ada catatan'), findsOneWidget);
    });

    testWidgets('menampilkan daftar catatan', (tester) async {
      await pumpPage(tester, FakeNoteRepository(notes: seed));

      expect(find.text('Belanja bulanan'), findsOneWidget);
      expect(find.text('Tugas Flutter'), findsOneWidget);
      expect(find.text('Belum ada catatan'), findsNothing);
    });

    testWidgets('menampilkan pesan error dan tombol coba lagi', (
      tester,
    ) async {
      final repo = FakeNoteRepository(
        failure: const LocalFailure('Database tidak bisa dibuka'),
      );
      await pumpPage(tester, repo);

      expect(find.textContaining('Gagal memuat catatan'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('menampilkan jumlah catatan belum tersinkron', (tester) async {
      final repo = FakeNoteRepository(notes: [
        Note(id: 1, title: 'A', updatedAt: DateTime(2026), dirty: true),
        Note(id: 2, title: 'B', updatedAt: DateTime(2026)),
      ]);
      await pumpPage(tester, repo);

      expect(find.text('1 catatan belum tersinkron'), findsOneWidget);
    });
  });

  group('NotesPage - tambah catatan', () {
    testWidgets('judul kosong ditolak dan dialog tetap terbuka', (
      tester,
    ) async {
      final repo = FakeNoteRepository();
      await pumpPage(tester, repo);

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Catatan'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Judul'), '   ');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Catatan'), findsOneWidget); // dialog masih ada
      expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
      expect(repo.notes, isEmpty); // tidak ada yang tersimpan
    });

    testWidgets('judul valid menambah catatan ke daftar', (tester) async {
      final repo = FakeNoteRepository();
      await pumpPage(tester, repo);

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Judul'),
        '  Baca materi  ',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Catatan'), findsNothing); // dialog tertutup
      expect(find.text('Baca materi'), findsOneWidget); // judul sudah di-trim
      expect(repo.notes.single.title, 'Baca materi');
    });

    testWidgets('tombol Batal menutup dialog tanpa menyimpan', (tester) async {
      final repo = FakeNoteRepository();
      await pumpPage(tester, repo);

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Catatan'), findsNothing);
      expect(repo.notes, isEmpty);
    });
  });

  group('NotesPage - hapus catatan', () {
    testWidgets('menghapus catatan dari daftar', (tester) async {
      final repo = FakeNoteRepository(notes: seed);
      await pumpPage(tester, repo);

      await tester.tap(find.byTooltip('Hapus').first); // 'Belanja bulanan'
      await tester.pumpAndSettle();

      expect(find.text('Belanja bulanan'), findsNothing);
      expect(find.text('Tugas Flutter'), findsOneWidget);
      expect(repo.notes.map((n) => n.id), [2]);
    });

    testWidgets('menampilkan snackbar saat hapus gagal', (tester) async {
      final repo = FakeNoteRepository(
        notes: seed,
        deleteFailure: const LocalFailure('Database terkunci'),
      );
      await pumpPage(tester, repo);

      await tester.tap(find.byTooltip('Hapus').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Gagal menghapus catatan: Database terkunci'),
        findsOneWidget,
      );
      expect(find.text('Belanja bulanan'), findsOneWidget); // tetap ada
    });
  });

  group('NotesPage - sinkronisasi', () {
    final dirtySeed = [
      Note(id: 1, title: 'A', updatedAt: DateTime(2026), dirty: true),
    ];

    testWidgets('tombol Sync nonaktif jika semua sudah tersinkron', (
      tester,
    ) async {
      await pumpPage(tester, FakeNoteRepository(notes: seed));

      expect(find.text('Semua catatan sudah tersinkron'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Sync'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('sinkronisasi berhasil menampilkan snackbar', (tester) async {
      final repo = FakeNoteRepository(notes: dirtySeed);
      await pumpPage(tester, repo);
      expect(find.text('1 catatan belum tersinkron'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Sync'));
      await tester.pump(); // mulai sinkronisasi
      await tester.pump(const Duration(seconds: 2)); // lewati delay 1 detik
      await tester.pumpAndSettle();

      expect(find.text('Sinkronisasi berhasil'), findsOneWidget);
      expect(repo.markSyncedCalls, 1);
    });

    testWidgets('sinkronisasi gagal menampilkan pesan error', (tester) async {
      final repo = FakeNoteRepository(
        notes: dirtySeed,
        markSyncedFailure: const LocalFailure('Disk penuh'),
      );
      await pumpPage(tester, repo);

      await tester.tap(find.widgetWithText(TextButton, 'Sync'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Sinkronisasi gagal: Disk penuh'), findsOneWidget);
    });
  });
}