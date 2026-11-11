import '../../../../core/failures.dart';
import '../entities/post.dart';

typedef PostsResult = ({List<Post> posts, Failure? failure, bool fromCache});

abstract class PostsRepository {
  Future<PostsResult> fetchPosts({required bool forceOffline});
}
