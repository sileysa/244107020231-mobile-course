import 'package:flutter_test/flutter_test.dart';

import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson aman ketika field hilang', () {
    final json = <String, dynamic>{
      'postId': 1,
      'id': 10,
      'name': 'Test Comment',
    };

    final comment = Comment.fromJson(json);

    expect(comment.postId, 1);
    expect(comment.id, 10);
    expect(comment.name, 'Test Comment');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson menggunakan nilai default ketika field null', () {
    final json = <String, dynamic>{
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    };

    final comment = Comment.fromJson(json);

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}