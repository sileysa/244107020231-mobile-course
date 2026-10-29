import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_feature_integration/features/notes/data/models/note_model.dart';

void main() {
  test('NoteModel handles absent SQLite fields', () {
    final note = NoteModel.fromMap({'title': 'Belanja'});

    expect(note.title, 'Belanja');
    expect(note.body, isEmpty);
    expect(note.dirty, isFalse);
    expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('NoteModel maps entity fields to and from SQLite', () {
    final source = NoteModel(
      id: 4,
      title: 'Tes',
      body: 'Isi',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );

    final restored = NoteModel.fromMap(source.toMap());

    expect(restored.id, source.id);
    expect(restored.title, source.title);
    expect(restored.body, source.body);
    expect(restored.updatedAt, source.updatedAt);
    expect(restored.dirty, isTrue);
  });
}
