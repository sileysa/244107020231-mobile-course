enum ChatMessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  const ChatMessage.user(String text)
    : this(role: ChatMessageRole.user, text: text);

  const ChatMessage.assistant(String text)
    : this(role: ChatMessageRole.assistant, text: text);

  final ChatMessageRole role;
  final String text;
}
