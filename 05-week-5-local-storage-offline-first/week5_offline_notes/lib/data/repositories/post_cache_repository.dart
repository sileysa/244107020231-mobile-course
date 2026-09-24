import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../models/post.dart';

class PostCacheRepository {
  PostCacheRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Post>> fetchCachedPosts() async {
    final db = await _openDb();

    final rows = await db.query(
      'cached_posts',
      orderBy: 'id ASC',
    );

    return rows.map((row) {
      final payload = row['payload'] as String;

      return Post.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> savePosts(List<Post> posts) async {
    final db = await _openDb();

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
}