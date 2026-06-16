import 'package:dio/dio.dart';

/// API error mapper utility class
/// Maps DioException errors to form field-specific error messages
class ApiErrorMapper {
  // Private constructor to prevent instantiation
  ApiErrorMapper._();

  /// Maps DioException to field-specific errors
  /// Returns a map of field names to error messages
  static Map<String, String> mapErrorToFields(DioException error) {
    final errors = <String, String>{};

    // Handle bad response (4xx, 5xx)
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          // Bad request - usually validation errors
          if (data is Map<String, dynamic>) {
            final message = data['message']?.toString() ?? '';
            
            // Map common validation errors to fields
            if (message.contains('username') || message.contains('Username')) {
              errors['username'] = 'Username sudah digunakan';
            }
            if (message.contains('email') || message.contains('Email')) {
              errors['email'] = 'Email sudah terdaftar';
            }
            if (message.contains('nik') || message.contains('NIK')) {
              errors['nik'] = 'NIK sudah terdaftar';
            }
            
            // If no specific field mapping, use general form error
            if (errors.isEmpty) {
              errors['_form'] = message.isNotEmpty 
                  ? message 
                  : 'Data tidak valid, silakan periksa kembali';
            }
          }
          break;

        case 401:
          // Unauthorized - invalid credentials
          errors['password'] = 'Username atau password tidak valid';
          break;

        case 404:
          // Not found
          errors['_form'] = 'Data tidak ditemukan';
          break;

        case 500:
        case 502:
        case 503:
          // Server errors
          errors['_form'] = 'Terjadi kesalahan server, silakan coba lagi';
          break;

        default:
          errors['_form'] = extractErrorMessage(error);
      }
    } else {
      // Network or other errors
      errors['_form'] = extractErrorMessage(error);
    }

    return errors;
  }

  /// Extracts user-friendly message from API response
  /// Returns a readable error message string
  static String extractErrorMessage(DioException error) {
    // Check for response data message
    if (error.response?.data is Map) {
      final message = error.response?.data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }

    // Check for DioException type
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout, silakan coba lagi';

      case DioExceptionType.connectionError:
        return 'Koneksi internet bermasalah, silakan coba lagi';

      case DioExceptionType.badResponse:
        return _getStatusMessage(error.response?.statusCode ?? 0);

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan';

      default:
        return 'Terjadi kesalahan, silakan coba lagi';
    }
  }

  /// Checks if error is network-related
  /// Returns true if the error is due to network issues
  static bool isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Maps HTTP status codes to user messages
  /// Returns a user-friendly message for the given status code
  static String getStatusMessage(int statusCode) {
    return _getStatusMessage(statusCode);
  }

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
