import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    if (id == null) {
      throw const FormatException('Post tidak memiliki ID yang valid.');
    }

    return PostModel(
      id: id,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'body': body};

  Post toEntity() => Post(id: id, title: title, body: body);
}
