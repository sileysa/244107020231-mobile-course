import '../../../../core/failures.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetRemotePosts {
  const GetRemotePosts(this._repository);

  final PostRepository _repository;

  Future<({List<Post> posts, Failure? failure})> call() {
    return _repository.fetchRemotePosts();
  }
}
