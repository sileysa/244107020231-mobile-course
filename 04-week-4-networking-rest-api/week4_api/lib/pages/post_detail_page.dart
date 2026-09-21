import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/providers.dart';

final postDetailProvider =
    FutureProvider.family<Post, int>((ref, id) async {
  // Cek apakah post sudah tersedia dari list yang sudah dimuat.
  final listState = ref.read(postListProvider);

  final loadedPosts = listState.asData?.value;

  if (loadedPosts != null) {
    for (final post in loadedPosts) {
      if (post.id == id) {
        return post;
      }
    }
  }

  // Jika belum ada di list, ambil langsung dari repository.
  final repository = ref.read(postRepositoryProvider);

  final posts = await repository.fetchPosts();

  for (final post in posts) {
    if (post.id == id) {
      return post;
    }
  }

  throw StateError('Post dengan ID $id tidak ditemukan.');
});

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    super.key,
    required this.id,
  });

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
      ),
      body: postAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(postDetailProvider(id));
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}