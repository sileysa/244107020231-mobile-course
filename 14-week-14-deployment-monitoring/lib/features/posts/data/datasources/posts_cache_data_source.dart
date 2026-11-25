import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/post_model.dart';

class PostsCacheDataSource {
  PostsCacheDataSource(this._openDb);

  final Future<Database> Function() _openDb;

  Future<List<PostModel>> fetchCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');

    return rows.map((row) {
      final payload = row['payload'] as String;
      return PostModel.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> savePosts(List<PostModel> posts) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      for (final post in posts) {
        await txn.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
