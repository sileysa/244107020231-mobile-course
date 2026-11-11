import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/chat/data/datasources/ai_service.dart';
import 'package:week7_clean_architecture/features/chat/data/repositories/chat_repository_impl.dart';

const _okBody =
    '{"candidates":[{"content":{"parts":[{"text":"Halo dari AI"}]}}]}';

ChatRepositoryImpl _repo(MockClient client) =>
    ChatRepositoryImpl(AiService(client: client));

MockClient _status(int code, [String body = '{}']) =>
    MockClient((_) async => http.Response(body, code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key'});
  });

  test('200 menghasilkan teks balasan', () async {
    final result = await _repo(_status(200, _okBody)).ask('halo');
    expect(result.reply, 'Halo dari AI');
    expect(result.failure, isNull);
  });

  test('API key dikirim lewat header, bukan di URL', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(_okBody, 200);
    });

    await _repo(client).ask('halo');

    expect(captured.headers['x-goog-api-key'], 'test-key');
    expect(captured.url.toString(), isNot(contains('key=')));
    expect(captured.url.toString(), isNot(contains('test-key')));
  });

  test('tanpa API key menghasilkan AuthenticationFailure', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final result = await _repo(_status(200, _okBody)).ask('halo');
    expect(result.failure, isA<AuthenticationFailure>());
  });

  test('status 400/401/403 menghasilkan AuthenticationFailure', () async {
    for (final code in [400, 401, 403]) {
      final result = await _repo(_status(code)).ask('halo');
      expect(result.failure, isA<AuthenticationFailure>(), reason: '$code');
    }
  });

  test('status 429, 503, dan 404 menghasilkan NetworkFailure', () async {
    for (final code in [429, 503, 404]) {
      final result = await _repo(_status(code)).ask('halo');
      expect(result.failure, isA<NetworkFailure>(), reason: '$code');
    }
  });

  test('respons 200 yang formatnya salah menghasilkan NetworkFailure', () async {
    final result = await _repo(_status(200, '{"foo":1}')).ask('halo');
    expect(result.failure, isA<NetworkFailure>());
    expect(result.reply, isNull);
  });

  test('timeout menghasilkan NetworkFailure', () async {
    final client = MockClient((_) async => throw TimeoutException('lama'));
    final result = await _repo(client).ask('halo');
    expect(result.failure, isA<NetworkFailure>());
  });

  test('error koneksi menghasilkan NetworkFailure', () async {
    final client = MockClient((_) async => throw http.ClientException('putus'));
    final result = await _repo(client).ask('halo');
    expect(result.failure, isA<NetworkFailure>());
  });
}