import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gemini_sse_decoder.dart';
import '../domain/ai_chat_failure.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/ai_chat_repository.dart';

class GeminiChatRepository implements AiChatRepository {
  GeminiChatRepository({
    Dio? dio,
    FlutterSecureStorage? storage,
    this.model = 'gemini-3.5-flash-lite',
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 60),
             ),
           ),
       _storage = storage ?? const FlutterSecureStorage();

  static const _apiKeyStorageKey = 'gemini_api_key';
  static const _apiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _systemInstruction =
      'Kamu adalah asisten kampus yang ramah. Jawab dalam Bahasa Indonesia '
      'dengan jelas dan ringkas. Jangan meminta atau mengungkap data pribadi.';

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String model;

  @override
  Stream<String> streamReply(List<ChatMessage> conversation) async* {
    final apiKey = await _readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiChatFailure(
        'API key belum diatur. Tambahkan API key melalui tombol pengaturan.',
      );
    }

    try {
      final response = await _dio.post<ResponseBody>(
        '$_apiBaseUrl/models/$model:streamGenerateContent',
        queryParameters: const {'alt': 'sse'},
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ),
        data: {
          'system_instruction': {
            'parts': [
              {'text': _systemInstruction},
            ],
          },
          'contents': conversation
              .map(
                (message) => {
                  'role': message.role == ChatMessageRole.user
                      ? 'user'
                      : 'model',
                  'parts': [
                    {'text': message.text},
                  ],
                },
              )
              .toList(),
        },
      );

      final body = response.data;
      if (body == null) {
        throw const AiChatFailure(
          'Layanan AI tidak mengembalikan respons. Silakan coba lagi.',
        );
      }

      yield* GeminiSseDecoder.decode(body.stream)
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const AiChatFailure(
        'Gemini tidak mengirim data selama 60 detik. Coba lagi atau periksa '
        'status layanan Gemini.',
      );
    } on DioException catch (error) {
      throw _failureForError(error);
    } on FormatException {
      throw const AiChatFailure(
        'Respons AI tidak dapat dibaca. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const AiChatFailure('API key tidak boleh kosong.');
    }

    try {
      await _storage.write(key: _apiKeyStorageKey, value: trimmedKey);
    } on PlatformException {
      throw const AiChatFailure(
        'API key tidak dapat disimpan dengan aman di perangkat ini.',
      );
    }
  }

  @override
  Future<bool> hasApiKey() async => (await _readApiKey())?.isNotEmpty ?? false;

  @override
  Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _apiKeyStorageKey);
    } on PlatformException {
      throw const AiChatFailure('API key tidak dapat dihapus.');
    }
  }

  Future<String?> _readApiKey() async {
    try {
      return await _storage.read(key: _apiKeyStorageKey);
    } on PlatformException {
      throw const AiChatFailure(
        'API key tidak dapat dibaca dari penyimpanan aman.',
      );
    }
  }

  AiChatFailure _failureForError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return const AiChatFailure(
        'Layanan AI sedang bermasalah. Coba lagi beberapa saat nanti.',
      );
    }

    return switch (statusCode) {
      400 => const AiChatFailure(
        'Permintaan tidak dapat diproses. Periksa pertanyaan lalu coba lagi.',
      ),
      401 || 403 => const AiChatFailure(
        'API key ditolak. Periksa kembali API key di pengaturan.',
      ),
      404 => const AiChatFailure(
        'Model Gemini tidak ditemukan. Periksa ketersediaan model untuk API key.',
      ),
      429 => const AiChatFailure(
        'Batas penggunaan AI tercapai. Tunggu sebentar sebelum mencoba lagi.',
      ),
      _ => _failureForConnectionError(error),
    };
  }

  AiChatFailure _failureForConnectionError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => const AiChatFailure(
        'Koneksi ke Gemini melewati batas waktu. Periksa internet, VPN, atau '
        'firewall lalu coba lagi.',
      ),
      DioExceptionType.sendTimeout => const AiChatFailure(
        'Pengiriman pertanyaan ke Gemini timeout. Periksa koneksi lalu coba lagi.',
      ),
      DioExceptionType.receiveTimeout => const AiChatFailure(
        'Gemini tidak mengirim jawaban tepat waktu. Coba lagi beberapa saat nanti.',
      ),
      DioExceptionType.badCertificate => const AiChatFailure(
        'Sertifikat koneksi Gemini tidak dapat diverifikasi. Periksa tanggal '
        'perangkat atau konfigurasi jaringan.',
      ),
      DioExceptionType.connectionError => const AiChatFailure(
        'Emulator tidak dapat membuka koneksi HTTPS ke Gemini. Periksa akses '
        'internet, VPN, atau firewall.',
      ),
      DioExceptionType.cancel => const AiChatFailure(
        'Permintaan chat dibatalkan. Silakan coba lagi.',
      ),
      _ => AiChatFailure(
        'Request Gemini gagal${error.message == null ? '.' : ': ${error.message}'}',
      ),
    };
  }
}
