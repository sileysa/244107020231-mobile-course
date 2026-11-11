import '../../../../core/failures.dart';
import '../repositories/chat_repository.dart';

class SaveAiApiKey {
  const SaveAiApiKey(this._repository);

  final ChatRepository _repository;

  Future<Failure?> call(String key) async {
    final clean = key.trim();
    if (clean.isEmpty) {
      return const ValidationFailure('API key tidak boleh kosong');
    }
    return _repository.saveApiKey(clean);
  }
}