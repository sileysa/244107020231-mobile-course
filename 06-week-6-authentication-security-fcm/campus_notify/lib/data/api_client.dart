import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();

        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }

        handler.next(options);
      },

      onError: (e, handler) async {
        // Hanya menangani 401.
        if (e.response?.statusCode != 401) {
          return handler.next(e);
        }

        // Jangan retry lebih dari satu kali.
        final alreadyRetried =
            e.requestOptions.extra['retried'] == true;

        if (alreadyRetried) {
          await store.clear();
          return handler.next(e);
        }

        final refreshToken = await store.readRefresh();

        // Tidak ada refresh token -> paksa login ulang.
        if (refreshToken == null || refreshToken.isEmpty) {
          await store.clear();
          return handler.next(e);
        }

        try {
          // Refresh access token.
          final renewed = await auth.refresh(refreshToken);

          // Simpan access token baru.
          await store.save(
            access: renewed,
            refresh: refreshToken,
          );

          // Retry request satu kali.
          final requestOptions = e.requestOptions;

          requestOptions.extra['retried'] = true;
          requestOptions.headers['Authorization'] =
              'Bearer $renewed';

          final retry = await dio.fetch(requestOptions);

          return handler.resolve(retry);
        } catch (_) {
          // Refresh token juga sudah tidak valid.
          await store.clear();

          return handler.next(e);
        }
      },
    ),
  );

  return dio;
}