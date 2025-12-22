import 'package:dio/dio.dart';
import 'api_client.dart';

class ExamsApi {
  final ApiClient _client;
  ExamsApi(this._client);

  /// GET /exams/patients/:pasienId
  Future<List<Map<String, dynamic>>> listByPatient(int pasienId) async {
    try {
      final res = await _client.dio.get('/exams/patients/$pasienId');
      final data = res.data;

      // response: { "data": [ ... ] }
      final rows = (data is Map && data['data'] is List) ? data['data'] as List : <dynamic>[];

      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Gagal mengambil daftar pemeriksaan';
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> detail(int id) async {
    try {
      final res = await _client.dio.get('/exams/$id');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Gagal mengambil detail pemeriksaan');
      throw Exception(msg);
    }
  }
}
