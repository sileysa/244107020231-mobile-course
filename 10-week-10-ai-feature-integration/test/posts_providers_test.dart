import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/core/failures.dart';
import 'package:week10_ai_feature_integration/features/posts/domain/entities/post.dart';
import 'package:week10_ai_feature_integration/features/posts/domain/repositories/post_repository.dart';
import 'package:week10_ai_feature_integration/features/posts/presentation/providers/posts_providers.dart';

class PendingPostRepository implements PostRepository {
  final remotePosts = Completer<({List<Post> posts, Failure? failure})>();
  var saveCalls = 0;

  @override
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts() async =>
      (posts: const <Post>[], failure: null);

  @override
  Future<({List<Post> posts, Failure? failure})> fetchRemotePosts() =>
      remotePosts.future;

  @override
  Future<Failure?> savePosts(List<Post> posts) async {
    saveCalls++;
    return null;
  }
}

void main() {
  test('background refresh does not access a disposed provider', () async {
    final repository = PendingPostRepository();
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
    );

    await container.read(offlinePostsProvider.future);
    container.dispose();
    repository.remotePosts.complete((posts: const <Post>[], failure: null));
    await Future<void>.delayed(Duration.zero);

    expect(repository.saveCalls, 0);
  });

  test('manual refresh stops when its provider is disposed', () async {
    final repository = PendingPostRepository();
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(repository),
        forceOfflineProvider.overrideWith((ref) => true),
      ],
    );

    await container.read(offlinePostsProvider.future);
    container.read(forceOfflineProvider.notifier).state = false;
    final refresh = container.read(offlinePostsProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    repository.remotePosts.complete((posts: const <Post>[], failure: null));
    await refresh;

    expect(repository.saveCalls, 0);
  });
}
