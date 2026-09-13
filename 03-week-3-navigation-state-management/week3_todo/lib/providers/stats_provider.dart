import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_provider.dart';

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final todos = ref.watch(todoListProvider);

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final random = Random();

    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    final total = todos.length;
    final selesai = todos.where((todo) => todo.done).length;
    final belumSelesai = total - selesai;

    return [
      'Total Tugas: $total',
      'Tugas Selesai: $selesai',
      'Tugas Belum Selesai: $belumSelesai',
    ];
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);