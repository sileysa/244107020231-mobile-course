import 'dart:convert';

class GeminiSseDecoder {
  const GeminiSseDecoder._();

  static Stream<String> decode(
    Stream<List<int>> stream, {
    Duration inactivityTimeout = const Duration(seconds: 60),
  }) async* {
    var buffer = '';
    await for (final chunk
        in stream
            .cast<List<int>>()
            .timeout(inactivityTimeout)
            .transform(utf8.decoder)) {
      buffer += chunk;
      var newline = buffer.indexOf('\n');
      while (newline != -1) {
        final line = buffer.substring(0, newline).trimRight();
        buffer = buffer.substring(newline + 1);
        final text = _textFromEventLine(line);
        if (text != null) yield text;
        newline = buffer.indexOf('\n');
      }
    }

    if (buffer.isNotEmpty) {
      final text = _textFromEventLine(buffer.trimRight());
      if (text != null) yield text;
    }
  }

  static String? _textFromEventLine(String line) {
    if (!line.startsWith('data:')) return null;

    final data = line.substring(5).trim();
    if (data.isEmpty || data == '[DONE]') return null;

    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = candidates.first;
    if (content is! Map<String, dynamic>) return null;
    final parts = content['content'];
    if (parts is! Map<String, dynamic>) return null;
    final responseParts = parts['parts'];
    if (responseParts is! List) return null;

    return responseParts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
  }
}
