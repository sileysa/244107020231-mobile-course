import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/delete_note.dart';

import 'fakes/fake_note_repository.dart';

void main() {
  final seed = [
    Note(id: 1, title: 'Belanja bulanan', updatedAt: DateTime(2026)),
    Note(id: 2, title: 'Tugas Flutter', updatedAt: DateTime(2026)),
  ];

  test('DeleteNote menghapus catatan yang dipilih', () async {
    final repo = FakeNoteRepository(notes: seed);

    final failure = await DeleteNote(repo).call(1);

    expect(failure, isNull);
    expect(repo.notes.map((n) => n.id), [2]);
  });

  test(
    'DeleteNote mengembalikan failure dan tidak menghapus apa pun',
    () async {
      final repo = FakeNoteRepository(
        notes: seed,
        deleteFailure: const LocalFailure('Database terkunci'),
      );

      final failure = await DeleteNote(repo).call(1);

      expect(failure, isA<LocalFailure>());
      expect(failure!.message, 'Database terkunci');
      expect(repo.notes, hasLength(2));
    },
  );
}
