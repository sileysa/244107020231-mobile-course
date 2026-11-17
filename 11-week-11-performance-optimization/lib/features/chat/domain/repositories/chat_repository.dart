import '../../../../core/failures.dart';

abstract class ChatRepository {
  Future<({String? reply, Failure? failure})> ask(String question);

  /// Setiap event berisi potongan teks (delta) atau satu failure.
  Stream<({String? delta, Failure? failure})> askStream(String question);

  Future<Failure?> saveApiKey(String key);
}