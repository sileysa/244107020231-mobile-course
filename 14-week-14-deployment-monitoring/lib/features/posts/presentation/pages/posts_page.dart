import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/posts_providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(postsProvider);
    await ref.read(postsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Posts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _OfflineControl(
            forceOffline: forceOffline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).setEnabled(value);
            },
          ),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorView(
                message: 'Posts gagal dimuat. Silakan coba lagi.',
                onRetry: () => _refresh(ref),
              ),
              data: (result) {
                if (result.failure != null && result.posts.isEmpty) {
                  return _ErrorView(
                    message: result.failure!.message,
                    onRetry: () => _refresh(ref),
                  );
                }
                if (result.posts.isEmpty) {
                  return const Center(child: Text('Belum ada data cache.'));
                }

                return Column(
                  children: [
                    if (result.failure != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 8),
                            Expanded(child: Text(result.failure!.message)),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _refresh(ref),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: result.posts.length,
                          itemBuilder: (context, index) {
                            final post = result.posts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${post.id}'),
                                ),
                                title: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    post.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineControl extends StatelessWidget {
  const _OfflineControl({required this.forceOffline, required this.onChanged});

  final bool forceOffline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(forceOffline ? Icons.cloud_off_outlined : Icons.cloud_outlined),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Force Offline',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Gunakan cache tanpa mengakses API',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: forceOffline, onChanged: onChanged),
        ],
      ),
    );
  }
}
