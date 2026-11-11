import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/posts/data/models/post_model.dart';

void main() {
  test('PostModel memetakan JSON ke entity dan kembali', () {
    final model = PostModel.fromJson({
      'id': 8,
      'title': 'Judul',
      'body': 'Isi',
    });

    expect(model.toEntity().id, 8);
    expect(model.toEntity().title, 'Judul');
    expect(model.toJson(), {'id': 8, 'title': 'Judul', 'body': 'Isi'});
  });

  test('PostModel menolak data tanpa ID', () {
    expect(
      () => PostModel.fromJson({'title': 'Judul', 'body': 'Isi'}),
      throwsFormatException,
    );
  });
}
