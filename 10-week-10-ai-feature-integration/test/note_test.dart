import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/data/models/note_model.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

import 'fakes/fake_note_repository.dart';

void main() {
  test('model aman terhadap field yang hilang', () {
    final note = NoteModel.fromMap({'title': 'Belanja'}).toEntity();

    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('flag dirty bertahan pada serialisasi model', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );

    final restored = NoteModel.fromMap(
      NoteModel(
        title: note.title,
        body: note.body,
        updatedAt: note.updatedAt,
        dirty: note.dirty,
      ).toMap(),
    ).toEntity();

    expect(restored.dirty, isTrue);
  });

  test('provider memuat catatan melalui repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            notes: [Note(title: 'Tes', updatedAt: DateTime(2026))],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(notesProvider.future);

    expect(result.failure, isNull);
    expect(result.notes, hasLength(1));
    expect(result.notes.single.title, 'Tes');
  });

  test('provider meneruskan kegagalan sebagai Failure domain', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(failure: const LocalFailure('db locked')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(notesProvider.future);

    expect(result.notes, isEmpty);
    expect(result.failure, isA<LocalFailure>());
    expect(result.failure?.message, 'db locked');
  });
}
