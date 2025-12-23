import 'package:dio/dio.dart';
import 'api_client.dart';

class PatientsApi {
  final ApiClient _client;
  PatientsApi(this._client);

  /// GET /patients
  Future<List<Map<String, dynamic>>> listPatients() async {
    try {
      final res = await _client.dio.get('/patients');
      final data = res.data;

      final List rows = (data is Map && data['items'] is List)
          ? (data['items'] as List)
          : <dynamic>[];

      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['message'] != null)
              ? e.response?.data['message'].toString()
              : (e.message ?? 'Gagal mengambil daftar pasien');
      throw Exception(msg);
    }
  }

  /// GET /patients/:id
  Future<Map<String, dynamic>> detail(int id) async {
    try {
      final res = await _client.dio.get('/patients/$id');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['message'] != null)
              ? e.response?.data['message'].toString()
              : (e.message ?? 'Gagal mengambil detail pasien');
      throw Exception(msg);
    }
  }
}
