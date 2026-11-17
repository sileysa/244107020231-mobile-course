import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/chat/domain/repositories/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.reply = 'balasan', this.failure, this.chunks});

  final String reply;
  final Failure? failure;
  final List<String>? chunks;
  final asked = <String>[];

  @override
  Future<({String? reply, Failure? failure})> ask(String question) async {
    asked.add(question);
    return (reply: failure == null ? reply : null, failure: failure);
  }

  @override
  Stream<({String? delta, Failure? failure})> askStream(
    String question,
  ) async* {
    asked.add(question);
    final parts = chunks ?? (failure == null ? [reply] : <String>[]);
    for (final part in parts) {
      yield (delta: part, failure: null);
    }
    if (failure != null) yield (delta: null, failure: failure);
  }

  @override
  Future<Failure?> saveApiKey(String key) async => null;
}