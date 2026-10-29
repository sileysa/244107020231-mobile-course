import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/core/format.dart';

void main() {
  test('route id parser handles valid and invalid values', () {
    expect(parseNoteRouteId('42'), 42);
    expect(parseNoteRouteId(null), isNull);
    expect(parseNoteRouteId('not-an-id'), isNull);
  });

  test('date formatter produces local date string', () {
    final date = DateTime(2026, 9, 27, 13);
    expect(formatNoteDate(date), date.toLocal().toString());
  });
}
