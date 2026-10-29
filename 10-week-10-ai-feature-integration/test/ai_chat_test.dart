import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/features/ai_chat/domain/entities/chat_message.dart';
import 'package:week10_ai_feature_integration/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:week10_ai_feature_integration/features/ai_chat/domain/usecases/validate_chat_prompt.dart';
import 'package:week10_ai_feature_integration/features/ai_chat/presentation/providers/ai_chat_provider.dart';

class FakeAiChatRepository implements AiChatRepository {
  final requests = <List<ChatMessage>>[];

  @override
  Stream<String> streamReply(List<ChatMessage> conversation) async* {
    requests.add(conversation);
    yield 'Jawaban ';
    yield 'AI';
  }

  @override
  Future<void> deleteApiKey() async {}

  @override
  Future<bool> hasApiKey() async => true;

  @override
  Future<void> saveApiKey(String apiKey) async {}
}

void main() {
  group('validateChatPrompt', () {
    test('menolak NIK, nomor telepon, email, dan alamat', () {
      expect(validateChatPrompt('NIK saya 1234567890123456'), isNotNull);
      expect(validateChatPrompt('Hubungi saya 081234567890'), isNotNull);
      expect(validateChatPrompt('Email saya user@example.com'), isNotNull);
      expect(validateChatPrompt('Alamat saya Jalan Melati nomor 3'), isNotNull);
    });

    test('menerima pertanyaan umum dan menolak input terlalu panjang', () {
      expect(validateChatPrompt('Kapan jadwal kuliah?'), isNull);
      expect(validateChatPrompt('a' * 1201), contains('1.200'));
    });
  });

  group('AiChatNotifier', () {
    test('streaming menggabungkan potongan jawaban ke state chat', () async {
      final repository = FakeAiChatRepository();
      final container = ProviderContainer(
        overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(aiChatProvider.notifier).send('Jadwal kampus?');

      final state = container.read(aiChatProvider);
      expect(state.isSending, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.messages, hasLength(2));
      expect(state.messages.last.text, 'Jawaban AI');
      expect(repository.requests.single.single.text, 'Jadwal kampus?');
    });

    test('input pribadi diblokir sebelum request ke repository', () async {
      final repository = FakeAiChatRepository();
      final container = ProviderContainer(
        overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(aiChatProvider.notifier)
          .send('NIK saya 1234567890123456');

      expect(repository.requests, isEmpty);
      expect(
        container.read(aiChatProvider).errorMessage,
        contains('data pribadi'),
      );
    });

    test(
      'konteks dibatasi dan request selalu diawali pesan pengguna',
      () async {
        final repository = FakeAiChatRepository();
        final container = ProviderContainer(
          overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(aiChatProvider.notifier);
        for (var index = 0; index < 6; index++) {
          await notifier.send('Pertanyaan umum $index');
        }

        final lastRequest = repository.requests.last;
        expect(lastRequest.length, lessThanOrEqualTo(10));
        expect(lastRequest.first.role, ChatMessageRole.user);
        expect(lastRequest.last.role, ChatMessageRole.user);
      },
    );
  });
}
