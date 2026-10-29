import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/features/notes/domain/entities/note.dart';
import 'package:week10_ai_feature_integration/features/notes/domain/usecases/search_notes.dart';

void main() {
  const searchNotes = SearchNotes();
  final notes = [
    Note(
      title: 'Belanja Bulanan',
      body: 'Beli sabun',
      updatedAt: DateTime(2026, 10, 1),
    ),
    Note(
      title: 'Agenda',
      body: 'Belanja kebutuhan rumah',
      updatedAt: DateTime(2026, 10, 2),
    ),
  ];

  test('pencarian judul mengabaikan huruf besar dan kecil', () {
    final result = searchNotes(notes, 'belanja');

    expect(result, hasLength(1));
    expect(result.single.title, 'Belanja Bulanan');
  });

  test('query yang tidak cocok mengembalikan daftar kosong', () {
    expect(searchNotes(notes, 'zzz-tak-ada'), isEmpty);
  });

  test('query kosong mengembalikan semua catatan', () {
    expect(searchNotes(notes, '  '), same(notes));
  });
}
