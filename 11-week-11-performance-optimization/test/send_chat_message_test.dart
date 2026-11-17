import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/chat/domain/usecases/send_chat_message.dart';

import 'fakes/fake_chat_repository.dart';

void main() {
  test('pesan kosong ditolak dan tidak dikirim ke AI', () async {
    final repo = FakeChatRepository();
    final result = await SendChatMessage(repo)('   ');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.reply, isNull);
    expect(repo.asked, isEmpty);
  });

  test('pesan lebih dari batas ditolak', () async {
    final repo = FakeChatRepository();
    final longText = 'a' * (SendChatMessage.maxLength + 1);
    final result = await SendChatMessage(repo)(longText);

    expect(result.failure, isA<ValidationFailure>());
    expect(repo.asked, isEmpty);
  });

  test('pesan valid di-trim lalu diteruskan ke repository', () async {
    final repo = FakeChatRepository(reply: 'Halo!');
    final result = await SendChatMessage(repo)('  halo  ');

    expect(result.reply, 'Halo!');
    expect(result.failure, isNull);
    expect(repo.asked, ['halo']);
  });
}