import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: statsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stack) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gagal memuat data: $error',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(statsProvider.notifier)
                        .retry();
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        },
        data: (stats) {
          return ListView.builder(
            itemCount: stats.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(stats[index]),
              );
            },
          );
        },
      ),
    );
  }
}