import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/offline_posts_provider.dart';
import '../data/offline_providers.dart';

class OfflinePostsPage extends ConsumerWidget {
  const OfflinePostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(offlinePostsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Posts'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(offlinePostsProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _OfflineControl(
            forceOffline: forceOffline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).state = value;

              if (!value) {
                ref.read(offlinePostsProvider.notifier).refresh();
              } else {
                ref.invalidate(offlinePostsProvider);
              }
            },
          ),
          Expanded(
            child: postsAsync.when(
              loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (error, stackTrace) {
                return _ErrorView(
                  message: error.toString(),
                  onRetry: () {
                    ref
                        .read(offlinePostsProvider.notifier)
                        .refresh();
                  },
                );
              },
              data: (posts) {
                if (posts.isEmpty) {
                  return const _EmptyView();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(offlinePostsProvider.notifier)
                        .refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineControl extends StatelessWidget {
  const _OfflineControl({
    required this.forceOffline,
    required this.onChanged,
  });

  final bool forceOffline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            forceOffline
                ? Icons.cloud_off_outlined
                : Icons.cloud_outlined,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Force Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gunakan cache tanpa mengakses API',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: forceOffline,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(
              Icons.cloud_off,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada data cache',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aktifkan koneksi internet untuk mengambil data.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}