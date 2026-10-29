import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/features/ai_chat/data/gemini_sse_decoder.dart';

void main() {
  test('membaca potongan SSE termasuk karakter UTF-8 terbelah', () async {
    final event =
        'data: {"candidates":[{"content":{"parts":[{"text":"Halo café"}]}}]}\n';
    final bytes = utf8.encode(event);
    final splitAt = event.indexOf('é') + 1;
    final decoded = GeminiSseDecoder.decode(
      Stream.fromIterable([bytes.sublist(0, splitAt), bytes.sublist(splitAt)]),
    );

    await expectLater(decoded, emitsInOrder(['Halo café', emitsDone]));
  });

  test('membaca stream Uint8List seperti response stream Dio', () async {
    final event =
        'data: {"candidates":[{"content":{"parts":[{"text":"Jawaban"}]}}]}\n';
    final decoded = GeminiSseDecoder.decode(
      Stream<Uint8List>.value(Uint8List.fromList(utf8.encode(event))),
    );

    await expectLater(decoded, emitsInOrder(['Jawaban', emitsDone]));
  });

  test('mengabaikan event kosong dan penanda akhir SSE', () async {
    final events = utf8.encode(
      'event: message\n'
      'data: \n'
      'data: [DONE]\n',
    );

    await expectLater(GeminiSseDecoder.decode(Stream.value(events)), emitsDone);
  });

  test('melaporkan payload JSON yang tidak valid', () async {
    final events = utf8.encode('data: {invalid}\n');

    await expectLater(
      GeminiSseDecoder.decode(Stream.value(events)),
      emitsError(isA<FormatException>()),
    );
  });

  test('mengakhiri stream yang tidak menerima chunk', () async {
    final controller = StreamController<List<int>>();
    addTearDown(controller.close);

    await expectLater(
      GeminiSseDecoder.decode(
        controller.stream,
        inactivityTimeout: const Duration(milliseconds: 10),
      ),
      emitsError(isA<TimeoutException>()),
    );
  });
}
