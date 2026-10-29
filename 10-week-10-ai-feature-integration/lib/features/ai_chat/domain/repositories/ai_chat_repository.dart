import '../entities/chat_message.dart';

abstract interface class AiChatRepository {
  Stream<String> streamReply(List<ChatMessage> conversation);

  Future<void> saveApiKey(String apiKey);

  Future<bool> hasApiKey();

  Future<void> deleteApiKey();
}
