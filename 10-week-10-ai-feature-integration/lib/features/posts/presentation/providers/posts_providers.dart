import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/data/datasources/notes_database.dart';
import '../../data/datasources/posts_api_data_source.dart';
import '../../data/datasources/posts_cache_data_source.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../domain/usecases/get_posts.dart';

final postsApiDataSourceProvider = Provider<PostsApiDataSource>((ref) {
  return PostsApiDataSource.createDefault();
});

final postsCacheDataSourceProvider = Provider<PostsCacheDataSource>((ref) {
  return PostsCacheDataSource(openNotesDb);
});

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepositoryImpl(
    ref.watch(postsApiDataSourceProvider),
    ref.watch(postsCacheDataSourceProvider),
  );
});

final getPostsProvider = Provider<GetPosts>((ref) {
  return GetPosts(ref.watch(postsRepositoryProvider));
});

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

final postsProvider = FutureProvider<PostsResult>((ref) {
  final forceOffline = ref.watch(forceOfflineProvider);
  return ref.watch(getPostsProvider).call(forceOffline: forceOffline);
});
