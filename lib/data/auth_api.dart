import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// LOGIN
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Login gagal';
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _client.dio.get('/auth/me');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Gagal mengambil data user';
      throw Exception(msg);
    }
  }
}
