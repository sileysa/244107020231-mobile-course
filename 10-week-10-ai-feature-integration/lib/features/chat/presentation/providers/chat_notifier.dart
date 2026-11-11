import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_providers.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.failure,
    this.lastQuestion,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final Failure? failure;
  final String? lastQuestion;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    Failure? failure,
    String? lastQuestion,
    bool clearFailure = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      lastQuestion: clearFailure ? null : (lastQuestion ?? this.lastQuestion),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isLoading) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: clean, fromUser: true)],
      clearFailure: true,
    );
    await _ask(clean);
  }

  /// Mengulang pertanyaan terakhir tanpa menambah bubble pengguna lagi.
  Future<void> retry() async {
    final question = state.lastQuestion;
    if (question == null || state.isLoading) return;
    state = state.copyWith(clearFailure: true);
    await _ask(question);
  }

  Future<void> _ask(String question) async {
    state = state.copyWith(isLoading: true);

    final buffer = StringBuffer();
    var started = false;
    Failure? failure;

    final events = ref.read(sendChatMessageProvider).stream(question);
    await for (final event in events) {
      if (event.failure != null) {
        failure = event.failure;
        break;
      }
      buffer.write(event.delta ?? '');
      final reply = ChatMessage(text: buffer.toString(), fromUser: false);
      final base = started
          ? state.messages.sublist(0, state.messages.length - 1)
          : state.messages;
      state = state.copyWith(messages: [...base, reply]);
      started = true;
    }

    if (failure != null) {
      // Buang balasan parsial supaya "Coba lagi" tidak menumpuk dua jawaban.
      final base = started
          ? state.messages.sublist(0, state.messages.length - 1)
          : state.messages;
      state = state.copyWith(
        messages: base,
        isLoading: false,
        failure: failure,
        lastQuestion: question,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void clear() {
    if (state.isLoading) return;
    state = const ChatState();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);