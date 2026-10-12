import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:sqflite/sqflite.dart';

import '../../../../data/local/db.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/get_remote_posts.dart';

final forceOfflineProvider = StateProvider<bool>((ref) => false);

final openPostsDbProvider = Provider<Future<Database> Function()>((ref) {
  return openNotesDb;
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(openDb: ref.watch(openPostsDbProvider));
});

final getRemotePostsProvider = Provider<GetRemotePosts>((ref) {
  return GetRemotePosts(ref.watch(postRepositoryProvider));
});

final offlinePostsProvider =
    AsyncNotifierProvider<OfflinePostsNotifier, List<Post>>(
      OfflinePostsNotifier.new,
    );

class OfflinePostsNotifier extends AsyncNotifier<List<Post>> {
  PostRepository get _repository => ref.read(postRepositoryProvider);

  @override
  Future<List<Post>> build() async {
    ref.watch(postRepositoryProvider);
    final cached = await _repository.fetchCachedPosts();
    if (cached.failure != null) throw cached.failure!;

    if (!ref.read(forceOfflineProvider)) {
      unawaited(_refreshFromApi());
    }
    return cached.posts;
  }

  Future<void> refresh() async {
    if (ref.read(forceOfflineProvider)) {
      final cached = await _repository.fetchCachedPosts();
      if (cached.failure != null) {
        state = AsyncError(cached.failure!, StackTrace.current);
      } else {
        state = AsyncData(cached.posts);
      }
      return;
    }

    state = const AsyncLoading();
    final remote = await ref.read(getRemotePostsProvider).call();
    if (remote.failure != null) {
      final cached = await _repository.fetchCachedPosts();
      if (cached.failure == null && cached.posts.isNotEmpty) {
        state = AsyncData(cached.posts);
      } else {
        state = AsyncError(
          cached.failure ?? remote.failure!,
          StackTrace.current,
        );
      }
      return;
    }

    final saveFailure = await _repository.savePosts(remote.posts);
    if (saveFailure != null) {
      state = AsyncError(saveFailure, StackTrace.current);
      return;
    }
    state = AsyncData(remote.posts);
  }

  Future<void> _refreshFromApi() async {
    final remote = await ref.read(getRemotePostsProvider).call();
    if (remote.failure != null) return;

    final saveFailure = await _repository.savePosts(remote.posts);
    if (saveFailure == null) state = AsyncData(remote.posts);
  }
}
