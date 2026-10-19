import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({Dio? dio, required this.openDb}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Future<Database> Function() openDb;

  @override
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts() async {
    try {
      final db = await openDb();
      final rows = await db.query('cached_posts', orderBy: 'id ASC');
      final posts = rows.map((row) {
        final payload = row['payload'] as String;
        return PostModel.fromJsonString(payload).toEntity();
      }).toList();
      return (posts: posts, failure: null);
    } catch (_) {
      return (
        posts: const <Post>[],
        failure: const LocalFailure(
          'Gagal membaca data cache. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<({List<Post> posts, Failure? failure})> fetchRemotePosts() async {
    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts',
      );
      final data = response.data as List<dynamic>;
      final posts = data
          .map(
            (item) =>
                PostModel.fromJson(item as Map<String, dynamic>).toEntity(),
          )
          .toList();
      return (posts: posts, failure: null);
    } on DioException {
      return (
        posts: const <Post>[],
        failure: const NetworkFailure(
          'Tidak dapat mengambil data dari server. Periksa koneksi internet.',
        ),
      );
    } catch (_) {
      return (
        posts: const <Post>[],
        failure: const NetworkFailure('Data dari server tidak dapat diproses.'),
      );
    }
  }

  @override
  Future<Failure?> savePosts(List<Post> posts) async {
    try {
      final db = await openDb();
      await db.transaction((txn) async {
        await txn.delete('cached_posts');
        for (final post in posts) {
          final model = PostModel.fromEntity(post);
          await txn.insert('cached_posts', {
            'id': model.id,
            'payload': model.toJsonString(),
            'cached_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      return null;
    } catch (_) {
      return const LocalFailure(
        'Gagal memperbarui data cache. Silakan coba lagi.',
      );
    }
  }
}
