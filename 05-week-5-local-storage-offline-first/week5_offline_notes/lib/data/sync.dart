import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';

/// Menyimpan Posts dari API ke cache SQLite.
Future<void> cachePosts(List<Post> posts) async {
  final db = await openNotesDb();

  await db.transaction((txn) async {
    await txn.delete('cached_posts');

    for (final post in posts) {
      await txn.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}

/// Melakukan simulasi sinkronisasi catatan.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  // Simulasi proses sinkronisasi ke server.
  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repo.markAllSynced();

  return dirtyCount;
}