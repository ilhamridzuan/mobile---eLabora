import 'package:dio/dio.dart';
import 'api_client.dart';

class RegisterApi {
  final ApiClient _client;
  RegisterApi(this._client);

  Future<Map<String, dynamic>> registerPasien({
    required String username,
    required String email,
    required String password,
    required String nik,
    required String nama,
    required String jenisKelamin, // "L" / "P"
    String? tglLahir, // "YYYY-MM-DD" atau null
    String? alamat,
    String? noTelepon,
  }) async {
    try {
      final payload = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'nik': nik,
        'nama': nama,
        'jenis_kelamin': jenisKelamin,
        'tgl_lahir': tglLahir, // boleh null
        'alamat': alamat, // boleh null
        'no_telepon': noTelepon, // boleh null
      };

      // ignore: avoid_print
      print('REGISTER /auth/register payload: $payload');

      final res = await _client.dio.post('/auth/register', data: payload);

      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Register gagal');
      throw Exception(msg);
    }
  }
}
