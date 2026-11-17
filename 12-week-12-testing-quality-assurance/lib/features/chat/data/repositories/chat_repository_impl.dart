import 'dart:async';

import '../../../../core/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/ai_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._service);

  final AiService _service;

  @override
  Future<({String? reply, Failure? failure})> ask(String question) async {
    try {
      final reply = await _service.ask(question);
      return (reply: reply, failure: null);
    } on Exception catch (e) {
      return (reply: null, failure: _toFailure(e));
    }
  }

  @override
  Stream<({String? delta, Failure? failure})> askStream(
    String question,
  ) async* {
    try {
      await for (final delta in _service.askStream(question)) {
        yield (delta: delta, failure: null);
      }
    } on Exception catch (e) {
      yield (delta: null, failure: _toFailure(e));
    }
  }

  @override
  Future<Failure?> saveApiKey(String key) async {
    try {
      await _service.saveApiKey(key);
      return null;
    } on Exception {
      return const LocalFailure('Gagal menyimpan API key');
    }
  }

  Failure _toFailure(Exception e) {
    if (e is AiKeyMissingException) {
      return const AuthenticationFailure('API key belum diatur');
    }
    if (e is AiApiException) return _fromStatus(e.statusCode);
    if (e is TimeoutException) {
      return const NetworkFailure('Layanan AI terlalu lama merespons');
    }
    if (e is AiResponseException) {
      return const NetworkFailure('Respons AI tidak dapat dibaca');
    }
    return const NetworkFailure('Tidak dapat terhubung ke layanan AI');
  }

  Failure _fromStatus(int code) {
    // Gemini membalas 400 untuk API key yang tidak valid.
    if (code == 400 || code == 401 || code == 403) {
      return const AuthenticationFailure(
        'API key tidak valid atau tidak punya akses',
      );
    }
    if (code == 429) {
      return const NetworkFailure('Terlalu banyak permintaan, coba lagi nanti');
    }
    if (code == 503) {
      return const NetworkFailure(
        'Layanan AI sedang ramai, coba lagi beberapa saat lagi',
      );
    }
    return NetworkFailure('Layanan AI bermasalah (kode $code)');
  }
}