import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/chat/presentation/providers/chat_notifier.dart';
import 'package:week7_clean_architecture/features/chat/presentation/providers/chat_providers.dart';

import 'fakes/fake_chat_repository.dart';

ProviderContainer _container(FakeChatRepository repo) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('pesan sukses menambah bubble pengguna dan balasan AI', () async {
    final container = _container(FakeChatRepository(reply: 'Halo!'));

    await container.read(chatProvider.notifier).send('halo');
    final state = container.read(chatProvider);

    expect(state.messages.map((m) => m.text), ['halo', 'Halo!']);
    expect(state.messages.map((m) => m.fromUser), [true, false]);
    expect(state.isLoading, isFalse);
    expect(state.failure, isNull);
  });

  test('kegagalan menyimpan failure dan tidak menambah balasan', () async {
    final container = _container(
      FakeChatRepository(failure: const NetworkFailure('gagal')),
    );

    await container.read(chatProvider.notifier).send('halo');
    final state = container.read(chatProvider);

    expect(state.messages.length, 1);
    expect(state.failure, isA<NetworkFailure>());
    expect(state.lastQuestion, 'halo');
    expect(state.isLoading, isFalse);
  });

  test('retry mengulang pertanyaan tanpa menggandakan bubble pengguna', () async {
    final repo = FakeChatRepository(failure: const NetworkFailure('gagal'));
    final container = _container(repo);
    final notifier = container.read(chatProvider.notifier);

    await notifier.send('halo');
    await notifier.retry();

    expect(repo.asked, ['halo', 'halo']);
    expect(container.read(chatProvider).messages.length, 1);
  });

  test('clear mengosongkan percakapan', () async {
    final container = _container(FakeChatRepository());
    final notifier = container.read(chatProvider.notifier);

    await notifier.send('halo');
    notifier.clear();

    expect(container.read(chatProvider).messages, isEmpty);
  });
}