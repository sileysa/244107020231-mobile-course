import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gemini_chat_repository.dart';
import '../../domain/ai_chat_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/usecases/validate_chat_prompt.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return GeminiChatRepository();
});

final apiKeyConfiguredProvider = FutureProvider<bool>((ref) {
  return ref.watch(aiChatRepositoryProvider).hasApiKey();
});

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.requestsSent = 0,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final int requestsSent;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    int? requestsSent,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      requestsSent: requestsSent ?? this.requestsSent,
    );
  }
}

class AiChatNotifier extends Notifier<AiChatState> {
  static const _maxRequestsPerSession = 20;
  static const _maxContextMessages = 10;

  @override
  AiChatState build() => const AiChatState();

  Future<void> send(String prompt) async {
    if (state.isSending) return;

    final validationError = validateChatPrompt(prompt);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    if (state.requestsSent >= _maxRequestsPerSession) {
      state = state.copyWith(
        errorMessage:
            'Batas 20 pertanyaan untuk sesi ini tercapai. '
            'Kembali lagi nanti atau gunakan catatan lokal.',
      );
      return;
    }

    final userMessage = ChatMessage.user(prompt.trim());
    final conversation = [...state.messages, userMessage];
    var contextStart = conversation.length > _maxContextMessages
        ? conversation.length - _maxContextMessages
        : 0;
    if (conversation[contextStart].role == ChatMessageRole.assistant) {
      contextStart++;
    }
    final requestContext = conversation.sublist(contextStart);
    var responseText = '';
    state = state.copyWith(
      messages: [...conversation, const ChatMessage.assistant('')],
      isSending: true,
      requestsSent: state.requestsSent + 1,
      clearError: true,
    );

    try {
      await for (final chunk
          in ref.read(aiChatRepositoryProvider).streamReply(requestContext)) {
        responseText += chunk;
        state = state.copyWith(
          messages: [...conversation, ChatMessage.assistant(responseText)],
        );
      }

      if (responseText.trim().isEmpty) {
        state = state.copyWith(
          messages: conversation,
          errorMessage:
              'AI tidak memberikan jawaban. Coba susun ulang pertanyaannya.',
        );
      }
    } on AiChatFailure catch (failure) {
      state = state.copyWith(
        messages: responseText.isEmpty
            ? conversation
            : [...conversation, ChatMessage.assistant(responseText)],
        errorMessage: failure.message,
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  void clearConversation() {
    if (state.isSending) return;
    state = AiChatState(requestsSent: state.requestsSent);
  }
}
