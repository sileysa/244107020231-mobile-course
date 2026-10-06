import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan yang tidak diketahui.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi timeout. Silakan coba lagi.';

    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;

      switch (statusCode) {
        case 401:
          return 'Sesi login telah berakhir. Silakan login kembali.';

        case 403:
          return 'Anda tidak memiliki izin untuk mengakses data ini.';

        case 404:
          return 'Data yang diminta tidak ditemukan.';

        case 500:
        case 502:
        case 503:
          return 'Server sedang mengalami masalah. Silakan coba lagi.';

        default:
          return 'Terjadi kesalahan pada server.';
      }

    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';

    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid.';

    case DioExceptionType.unknown:
      return 'Terjadi kesalahan koneksi.';
  }
}
