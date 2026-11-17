import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/posts/domain/entities/post.dart';
import 'package:week7_clean_architecture/features/posts/domain/repositories/posts_repository.dart';
import 'package:week7_clean_architecture/features/posts/domain/usecases/get_posts.dart';

class FakePostsRepository implements PostsRepository {
  FakePostsRepository({
    this.items = const [],
    this.failure,
    this.fromCache = false,
  });

  final List<Post> items;
  final Failure? failure;
  final bool fromCache;
  bool? requestedOffline;

  @override
  Future<PostsResult> fetchPosts({required bool forceOffline}) async {
    requestedOffline = forceOffline;
    return (posts: items, failure: failure, fromCache: fromCache);
  }
}

void main() {
  test('GetPosts meneruskan hasil repository dan mode offline', () async {
    final post = Post(id: 1, title: 'Pengumuman', body: 'Isi');
    final repository = FakePostsRepository(items: [post], fromCache: true);

    final result = await GetPosts(repository).call(forceOffline: true);

    expect(result.posts, [post]);
    expect(result.fromCache, isTrue);
    expect(result.failure, isNull);
    expect(repository.requestedOffline, isTrue);
  });

  test('GetPosts meneruskan failure jaringan secara eksplisit', () async {
    final repository = FakePostsRepository(
      failure: const NetworkFailure('Koneksi gagal.'),
      fromCache: true,
    );

    final result = await GetPosts(repository).call(forceOffline: false);

    expect(result.failure, isA<NetworkFailure>());
    expect(result.posts, isEmpty);
    expect(result.fromCache, isTrue);
  });
}
