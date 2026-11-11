import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/search_notes.dart';

void main() {
  final notes = [
    Note(title: 'Belanja bulanan', updatedAt: DateTime(2026)),
    Note(title: 'Daftar belanja', updatedAt: DateTime(2026)),
    Note(title: 'Tugas Flutter', updatedAt: DateTime(2026)),
  ];
  const search = SearchNotes();

  test('query cocok mengembalikan catatan yang sesuai', () {
    expect(search(notes, 'flutter'), hasLength(1));
  });

  test('pencarian abaikan huruf besar/kecil', () {
    expect(search(notes, 'BELANJA'), hasLength(2));
  });

  test('query tak cocok mengembalikan list kosong', () {
    expect(search(notes, 'zzz-tak-ada'), isEmpty);
  });

  test('query hanya spasi mengembalikan semua catatan', () {
    expect(search(notes, '   '), hasLength(3));
  });

  test('judul huruf besar cocok dengan query huruf kecil', () {
    final upper = [Note(title: 'FLUTTER', updatedAt: DateTime(2026))];
    expect(search(upper, 'flutter'), hasLength(1));
  });
}
