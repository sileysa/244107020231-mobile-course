import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'offline_providers.dart';
import 'repositories/post_cache_repository.dart';
import 'repositories/post_repository.dart';

final postCacheRepositoryProvider = Provider<PostCacheRepository>((ref) {
  return PostCacheRepository();
});

final offlinePostsProvider =
    AsyncNotifierProvider<OfflinePostsNotifier, List<Post>>(
  OfflinePostsNotifier.new,
);

class OfflinePostsNotifier extends AsyncNotifier<List<Post>> {
  late final PostCacheRepository _cacheRepository;
  late final PostRepository _apiRepository;

  @override
  Future<List<Post>> build() async {
    _cacheRepository = ref.read(postCacheRepositoryProvider);
    _apiRepository = PostRepository();

    final cachedPosts = await _cacheRepository.fetchCachedPosts();

    final forceOffline = ref.read(forceOfflineProvider);

    if (!forceOffline) {
      unawaited(_refreshFromApi());
    }

    return cachedPosts;
  }

  Future<void> refresh() async {
    final forceOffline = ref.read(forceOfflineProvider);

    if (forceOffline) {
      state = AsyncData(
        await _cacheRepository.fetchCachedPosts(),
      );
      return;
    }

    state = const AsyncLoading();

    try {
      final posts = await _apiRepository.fetchPosts();

      await _cacheRepository.savePosts(posts);

      state = AsyncData(posts);
    } catch (e, st) {
      final cachedPosts = await _cacheRepository.fetchCachedPosts();

      if (cachedPosts.isNotEmpty) {
        state = AsyncData(cachedPosts);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final posts = await _apiRepository.fetchPosts();

      await _cacheRepository.savePosts(posts);

      state = AsyncData(posts);
    } catch (_) {
      // Jika API gagal, cache tetap digunakan.
    }
  }
}