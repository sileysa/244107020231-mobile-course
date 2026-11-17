import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/sync_notes.dart';

import 'fakes/fake_note_repository.dart';

Note note(int id, {bool dirty = false}) =>
    Note(id: id, title: 'Catatan $id', updatedAt: DateTime(2026), dirty: dirty);

void main() {
  test('tidak ada catatan dirty: tidak memanggil markAllSynced', () async {
    final repo = FakeNoteRepository(notes: [note(1), note(2)]);

    final result = await SyncNotes(repo).call();

    expect(result.syncedCount, 0);
    expect(result.failure, isNull);
    expect(repo.markSyncedCalls, 0);
  });

  test('catatan dirty disinkronkan dan jumlahnya dilaporkan', () async {
    final repo = FakeNoteRepository(
      notes: [note(1, dirty: true), note(2, dirty: true), note(3)],
    );

    final result = await SyncNotes(repo).call(); // menunggu 1 detik asli

    expect(result.syncedCount, 2);
    expect(result.failure, isNull);
    expect(repo.markSyncedCalls, 1);
  });

  test('countDirty gagal: berhenti sebelum markAllSynced', () async {
    final repo = FakeNoteRepository(
      notes: [note(1, dirty: true)],
      failure: const LocalFailure('Database tidak bisa dibuka'),
    );

    final result = await SyncNotes(repo).call();

    expect(result.syncedCount, 0);
    expect(result.failure, isA<LocalFailure>());
    expect(repo.markSyncedCalls, 0);
  });

  test('markAllSynced gagal: syncedCount 0 dan failure diteruskan', () async {
    final repo = FakeNoteRepository(
      notes: [note(1, dirty: true)],
      markSyncedFailure: const NetworkFailure('Server tidak terjangkau'),
    );

    final result = await SyncNotes(repo).call();

    expect(result.syncedCount, 0);
    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, 'Server tidak terjangkau');
    expect(repo.markSyncedCalls, 1);
  });
}