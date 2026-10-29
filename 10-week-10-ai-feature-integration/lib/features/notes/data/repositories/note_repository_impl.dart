import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.openDb});

  final Future<Database> Function() openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows
          .map((row) => NoteModel.fromMap(row).toEntity())
          .toList();
      return (notes: notes, failure: null);
    } catch (_) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure(
          'Gagal membaca catatan. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await openDb();
      final model = NoteModel(
        title: title,
        body: body,
        updatedAt: DateTime.now(),
        dirty: true,
      );
      final id = await db.insert('notes', model.toMap());
      return (note: model.withId(id).toEntity(), failure: null);
    } catch (_) {
      return (
        note: null,
        failure: const LocalFailure(
          'Gagal menyimpan catatan. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    try {
      final db = await openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return null;
    } catch (_) {
      return const LocalFailure('Gagal menghapus catatan. Silakan coba lagi.');
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      final db = await openDb();
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
      );
      return (count: (rows.first['c'] as num?)?.toInt() ?? 0, failure: null);
    } catch (_) {
      return (
        count: 0,
        failure: const LocalFailure(
          'Gagal membaca antrean sinkronisasi. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<({int count, Failure? failure})> markAllSynced() async {
    try {
      final db = await openDb();
      final count = await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
      return (count: count, failure: null);
    } catch (_) {
      return (
        count: 0,
        failure: const LocalFailure(
          'Gagal memperbarui status sinkronisasi. Silakan coba lagi.',
        ),
      );
    }
  }
}
