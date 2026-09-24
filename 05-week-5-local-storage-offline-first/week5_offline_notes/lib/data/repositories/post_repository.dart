import 'package:dio/dio.dart';

import '../models/post.dart';

class PostRepository {
  PostRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get(
      'https://jsonplaceholder.typicode.com/posts',
    );

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => Post.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}