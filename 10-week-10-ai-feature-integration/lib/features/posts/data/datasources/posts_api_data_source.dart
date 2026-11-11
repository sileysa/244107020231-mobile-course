import 'package:dio/dio.dart';

import '../models/post_model.dart';

class PostsApiDataSource {
  PostsApiDataSource(this._dio);

  factory PostsApiDataSource.createDefault() {
    return PostsApiDataSource(Dio());
  }

  final Dio _dio;

  Future<List<PostModel>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>(
      'https://jsonplaceholder.typicode.com/posts',
    );
    final items = response.data;
    if (items == null) {
      throw const FormatException('Respons API posts tidak valid.');
    }

    return items
        .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
