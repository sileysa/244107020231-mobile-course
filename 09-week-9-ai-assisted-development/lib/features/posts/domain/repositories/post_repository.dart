import '../../../../core/failures.dart';
import '../entities/post.dart';

abstract class PostRepository {
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts();

  Future<({List<Post> posts, Failure? failure})> fetchRemotePosts();

  Future<Failure?> savePosts(List<Post> posts);
}
