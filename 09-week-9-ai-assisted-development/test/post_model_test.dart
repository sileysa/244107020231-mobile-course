import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/posts/data/models/post_model.dart';

void main() {
  test('PostModel maps API/cache JSON to the domain entity', () {
    final model = PostModel.fromJsonString(
      '{"id":7,"title":"Offline","body":"cached"}',
    );

    expect(model.toEntity().id, 7);
    expect(model.toEntity().title, 'Offline');
    expect(
      PostModel.fromEntity(model).toJsonString(),
      '{"id":7,"title":"Offline","body":"cached"}',
    );
  });
}
