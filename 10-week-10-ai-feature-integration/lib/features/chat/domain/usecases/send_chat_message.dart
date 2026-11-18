import '../../../../core/failures.dart';
import '../repositories/chat_repository.dart';

class SendChatMessage {
  const SendChatMessage(this._repository);

  static const maxLength = 500;

  final ChatRepository _repository;

  Failure? _validate(String clean) {
    if (clean.isEmpty) {
      return const ValidationFailure('Pesan tidak boleh kosong');
    }
    if (clean.length > maxLength) {
      return const ValidationFailure(
        'Pesan terlalu panjang (maksimal $maxLength karakter)',
      );
    }
    return null;
  }

  Future<({String? reply, Failure? failure})> call(String message) async {
    final clean = message.trim();
    final invalid = _validate(clean);
    if (invalid != null) return (reply: null, failure: invalid);
    return _repository.ask(clean);
  }

  Stream<({String? delta, Failure? failure})> stream(String message) {
    final clean = message.trim();
    final invalid = _validate(clean);
    if (invalid != null) {
      return Stream.value((delta: null, failure: invalid));
    }
    return _repository.askStream(clean);
  }
}