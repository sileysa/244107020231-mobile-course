import '../repositories/posts_repository.dart';

class GetPosts {
  const GetPosts(this._repository);

  final PostsRepository _repository;

  Future<PostsResult> call({required bool forceOffline}) {
    return _repository.fetchPosts(forceOffline: forceOffline);
  }
}
