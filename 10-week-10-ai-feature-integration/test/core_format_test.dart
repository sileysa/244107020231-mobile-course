import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/format.dart';

void main() {
  test('formatDateTime menghasilkan format tanggal konsisten', () {
    final formatted = formatDateTime(DateTime(2026, 9, 7, 8, 5).toLocal());

    expect(formatted, '07/09/2026 08:05');
  });

  test('parseRouteId menerima ID positif yang valid', () {
    expect(parseRouteId('42'), 42);
  });

  test('parseRouteId menolak nilai non-numerik dan ID non-positif', () {
    expect(parseRouteId(null), isNull);
    expect(parseRouteId('abc'), isNull);
    expect(parseRouteId('0'), isNull);
    expect(parseRouteId('-2'), isNull);
  });
}
