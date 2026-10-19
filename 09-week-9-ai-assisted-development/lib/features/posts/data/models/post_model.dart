import 'dart:convert';

import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  factory PostModel.fromJsonString(String source) {
    return PostModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  factory PostModel.fromEntity(Post post) {
    return PostModel(id: post.id, title: post.title, body: post.body);
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};

  String toJsonString() => jsonEncode(toJson());

  Post toEntity() => Post(id: id, title: title, body: body);
}
