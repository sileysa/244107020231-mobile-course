import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_api_data_source.dart';
import '../datasources/posts_cache_data_source.dart';

class PostsRepositoryImpl implements PostsRepository {
  const PostsRepositoryImpl(this._api, this._cache);

  final PostsApiDataSource _api;
  final PostsCacheDataSource _cache;

  @override
  Future<PostsResult> fetchPosts({required bool forceOffline}) async {
    if (forceOffline) {
      try {
        final cached = await _cache.fetchCachedPosts();
        return (
          posts: cached.map((post) => post.toEntity()).toList(),
          failure: null,
          fromCache: true,
        );
      } catch (_) {
        return (
          posts: const <Post>[],
          failure: const LocalFailure(
            'Data offline gagal dimuat. Silakan coba lagi.',
          ),
          fromCache: true,
        );
      }
    }

    try {
      final fetched = await _api.fetchPosts();
      try {
        await _cache.savePosts(fetched);
      } catch (_) {
        return (
          posts: fetched.map((post) => post.toEntity()).toList(),
          failure: const LocalFailure(
            'Data berhasil dimuat, tetapi cache offline gagal diperbarui.',
          ),
          fromCache: false,
        );
      }
      return (
        posts: fetched.map((post) => post.toEntity()).toList(),
        failure: null,
        fromCache: false,
      );
    } catch (_) {
      try {
        final cached = await _cache.fetchCachedPosts();
        if (cached.isNotEmpty) {
          return (
            posts: cached.map((post) => post.toEntity()).toList(),
            failure: const NetworkFailure(
              'Koneksi gagal. Menampilkan data cache yang tersimpan.',
            ),
            fromCache: true,
          );
        }
      } catch (_) {
        return (
          posts: const <Post>[],
          failure: const LocalFailure(
            'Koneksi gagal dan data cache tidak dapat dibaca.',
          ),
          fromCache: true,
        );
      }

      return (
        posts: const <Post>[],
        failure: const NetworkFailure(
          'Posts gagal dimuat. Periksa koneksi lalu coba lagi.',
        ),
        fromCache: true,
      );
    }
  }
}
