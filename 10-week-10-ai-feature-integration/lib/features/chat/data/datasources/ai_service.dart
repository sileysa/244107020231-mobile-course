import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiKeyMissingException implements Exception {
  const AiKeyMissingException();
}

class AiApiException implements Exception {
  const AiApiException(this.statusCode);

  final int statusCode;
}

class AiResponseException implements Exception {
  const AiResponseException();
}

class AiService {
  AiService({
    http.Client? client,
    FlutterSecureStorage? storage,
    this.model = defaultModel,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  static const defaultModel = 'gemini-3.8-flash';

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _keyName = 'ai_api_key';
  static const _timeout = Duration(seconds: 20);
  static const _systemPrompt =
      'Kamu asisten catatan yang ramah. Jawab dalam Bahasa Indonesia, '
      'maksimal 2 kalimat. Jangan meminta data pribadi pengguna.';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String model;

  Future<String> _readKey() async {
    final apiKey = await _storage.read(key: _keyName);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiKeyMissingException();
    }
    return apiKey;
  }

  Map<String, String> _headers(String apiKey) => {
    'Content-Type': 'application/json',
    'x-goog-api-key': apiKey,
  };

  String _body(String question) => jsonEncode({
    'system_instruction': {
      'parts': [
        {'text': _systemPrompt},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ],
  });

  Future<String> ask(String question) async {
    final apiKey = await _readKey();

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/$model:generateContent'),
          headers: _headers(apiKey),
          body: _body(question),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw AiApiException(response.statusCode);
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;
      final parts = candidates.first['content']['parts'] as List<dynamic>;
      final text = parts.map((p) => p['text'] ?? '').join().trim();
      if (text.isEmpty) throw const AiResponseException();
      return text;
    } on AiResponseException {
      rethrow;
    } catch (_) {
      throw const AiResponseException();
    }
  }

  /// Streaming lewat Server-Sent Events: tiap baris `data: {...}` berisi
  /// potongan teks. Timeout berlaku untuk koneksi awal dan jeda antar potongan.
  Stream<String> askStream(String question) async* {
    final apiKey = await _readKey();

    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/$model:streamGenerateContent?alt=sse'),
    )
      ..headers.addAll(_headers(apiKey))
      ..body = _body(question);

    final response = await _client.send(request).timeout(_timeout);

    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw AiApiException(response.statusCode);
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(_timeout);

    var gotText = false;
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;

      final text = _extractText(payload);
      if (text.isNotEmpty) {
        gotText = true;
        yield text;
      }
    }

    if (!gotText) throw const AiResponseException();
  }

  String _extractText(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return '';
      final parts = candidates.first['content']?['parts'] as List<dynamic>?;
      if (parts == null) return '';
      return parts.map((p) => p['text'] ?? '').join();
    } catch (_) {
      throw const AiResponseException();
    }
  }

  Future<void> saveApiKey(String key) =>
      _storage.write(key: _keyName, value: key);
}