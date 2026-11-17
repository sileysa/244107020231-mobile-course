import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ai_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/save_ai_api_key.dart';
import '../../domain/usecases/send_chat_message.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(aiServiceProvider));
});

final sendChatMessageProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(ref.watch(chatRepositoryProvider));
});

final saveAiApiKeyProvider = Provider<SaveAiApiKey>((ref) {
  return SaveAiApiKey(ref.watch(chatRepositoryProvider));
});