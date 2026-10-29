class AiChatFailure implements Exception {
  const AiChatFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
