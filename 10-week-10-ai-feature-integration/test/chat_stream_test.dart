import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/chat/data/datasources/ai_service.dart';
import 'package:week7_clean_architecture/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:week7_clean_architecture/features/chat/domain/usecases/send_chat_message.dart';
import 'package:week7_clean_architecture/features/chat/presentation/providers/chat_notifier.dart';
import 'package:week7_clean_architecture/features/chat/presentation/providers/chat_providers.dart';

import 'fakes/fake_chat_repository.dart';

const _sse =
    'data: {"candidates":[{"content":{"parts":[{"text":"Ha"}]}}]}\n\n'
    'data: {"candidates":[{"content":{"parts":[{"text":"lo"}]}}]}\n\n';

ChatRepositoryImpl _repo(MockClient client) =>
    ChatRepositoryImpl(AiService(client: client));

MockClient _status(int code, [String body = '']) =>
    MockClient((_) async => http.Response(body, code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key'});
  });

  group('AiService + repository (streaming)', () {
    test('potongan SSE diteruskan berurutan', () async {
      final events = await _repo(_status(200, _sse)).askStream('halo').toList();

      expect(events.map((e) => e.delta), ['Ha', 'lo']);
      expect(events.every((e) => e.failure == null), isTrue);
    });

    test('memakai endpoint stream dan key lewat header', () async {
      late http.BaseRequest captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(_sse, 200);
      });

      await _repo(client).askStream('halo').toList();

      expect(captured.url.path, contains('streamGenerateContent'));
      expect(captured.url.queryParameters['alt'], 'sse');
      expect(captured.headers['x-goog-api-key'], 'test-key');
      expect(captured.url.toString(), isNot(contains('test-key')));
    });

    test('status 503 menghasilkan satu NetworkFailure', () async {
      final events = await _repo(_status(503)).askStream('halo').toList();

      expect(events.length, 1);
      expect(events.single.failure, isA<NetworkFailure>());
      expect(events.single.delta, isNull);
    });

    test('tanpa API key menghasilkan AuthenticationFailure', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final events = await _repo(_status(200, _sse)).askStream('halo').toList();

      expect(events.single.failure, isA<AuthenticationFailure>());
    });

    test('stream tanpa teks dianggap respons tidak terbaca', () async {
      final events = await _repo(_status(200, '')).askStream('halo').toList();

      expect(events.single.failure, isA<NetworkFailure>());
    });
  });

  group('SendChatMessage.stream', () {
    test('pesan kosong menghasilkan ValidationFailure tanpa memanggil AI', () async {
      final repo = FakeChatRepository();
      final events = await SendChatMessage(repo).stream('   ').toList();

      expect(events.single.failure, isA<ValidationFailure>());
      expect(repo.asked, isEmpty);
    });
  });

  group('ChatNotifier (streaming)', () {
    ProviderContainer container(FakeChatRepository repo) {
      final c = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('potongan digabung menjadi satu bubble balasan', () async {
      final c = container(FakeChatRepository(chunks: ['Ha', 'lo', ' dunia']));

      await c.read(chatProvider.notifier).send('halo');
      final messages = c.read(chatProvider).messages;

      expect(messages.length, 2);
      expect(messages.last.text, 'Halo dunia');
      expect(messages.last.fromUser, isFalse);
    });

    test('gagal di tengah stream membuang balasan parsial', () async {
      final c = container(
        FakeChatRepository(
          chunks: ['Ha'],
          failure: const NetworkFailure('putus'),
        ),
      );

      await c.read(chatProvider.notifier).send('halo');
      final state = c.read(chatProvider);

      expect(state.messages.length, 1);
      expect(state.messages.single.fromUser, isTrue);
      expect(state.failure, isA<NetworkFailure>());
      expect(state.isLoading, isFalse);
    });
  });
}