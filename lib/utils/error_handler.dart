import 'package:dio/dio.dart';

/// Centralized error handler utility class
/// Provides consistent error handling across the application
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Handles any type of error and returns user-friendly message
  /// Returns a readable error message string
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return 'Format data tidak valid';
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return 'Terjadi kesalahan tidak terduga';
    }
  }

  /// Handles Dio-specific errors
  /// Returns a user-friendly error message
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout, silakan coba lagi';

      case DioExceptionType.connectionError:
        return 'Koneksi internet bermasalah, silakan coba lagi';

      case DioExceptionType.badResponse:
        return _extractApiError(error.response);

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan';

      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan tidak valid';

      case DioExceptionType.unknown:
      default:
        return 'Terjadi kesalahan, silakan coba lagi';
    }
  }

  /// Extracts error message from API response
  /// Returns a user-friendly error message
  static String _extractApiError(Response? response) {
    if (response == null) {
      return 'Terjadi kesalahan server';
    }

    // Try to extract message from response data
    if (response.data is Map) {
      final message = response.data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }

    // Fallback to status code message
    return _getStatusMessage(response.statusCode ?? 0);
  }

  /// Maps HTTP status codes to user messages
  /// Returns a user-friendly message for the given status code
  static String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid';
      case 401:
        return 'Autentikasi gagal';
      case 403:
        return 'Akses ditolak';
      case 404:
        return 'Data tidak ditemukan';
      case 408:
        return 'Permintaan timeout';
      case 409:
        return 'Data sudah ada';
      case 422:
        return 'Data tidak dapat diproses';
      case 429:
        return 'Terlalu banyak permintaan, silakan coba lagi nanti';
      case 500:
        return 'Terjadi kesalahan server';
      case 502:
        return 'Server tidak dapat dijangkau';
      case 503:
        return 'Layanan sedang tidak tersedia';
      case 504:
        return 'Server timeout';
      default:
        return 'Terjadi kesalahan (kode: $statusCode)';
    }
  }
}
