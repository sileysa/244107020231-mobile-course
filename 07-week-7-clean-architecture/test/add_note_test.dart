import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/add_note.dart';

import 'fakes/fake_note_repository.dart';

void main() {
  test('AddNote menolak judul kosong tanpa memanggil repository', () async {
    final result = await AddNote(FakeNoteRepository()).call(title: '');

    expect(result.note, isNull);
    expect(result.failure, isA<ValidationFailure>());
  });

  test('AddNote menolak judul yang hanya berisi spasi', () async {
    final result = await AddNote(FakeNoteRepository()).call(title: '   ');

    expect(result.note, isNull);
    expect(result.failure, isA<ValidationFailure>());
  });

  test('AddNote meneruskan judul yang sudah di-trim', () async {
    final result = await AddNote(FakeNoteRepository())
        .call(title: '  Belajar Flutter  ');

    expect(result.failure, isNull);
    expect(result.note!.title, 'Belajar Flutter');
  });
}
