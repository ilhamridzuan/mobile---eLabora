import 'package:dio/dio.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthApi {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthApi(this._client, this._tokenStorage);

  /// LOGIN
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final token = res.data['token'];
      if (token == null || token.toString().isEmpty) {
        throw Exception('Token tidak ditemukan dari server');
      }

      await _tokenStorage.saveToken(token);
      return token;
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Login gagal';
      throw Exception(msg);
    }
  }

  /// GET USER LOGIN
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
