import 'package:dio/dio.dart';
import 'api_client.dart';

class ExamsApi {
  final ApiClient _client;
  ExamsApi(this._client);

  /// GET /exams/all
  Future<List<Map<String, dynamic>>> listAll() async {
    try {
      final res = await _client.dio.get('/exams/all');
      final data = res.data;

      // support: { "data": [ ... ] } atau langsung [ ... ]
      final List rows = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : <dynamic>[]);

      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['message'] != null)
              ? e.response?.data['message'].toString()
              : (e.message ?? 'Gagal mengambil semua hasil pemeriksaan');
      throw Exception(msg);
    }
  }

  /// GET /exams/patients/:pasienId
  Future<List<Map<String, dynamic>>> listByPatient(int pasienId) async {
    try {
      final res = await _client.dio.get('/exams/patients/$pasienId');
      final data = res.data;

      // response: { "data": [ ... ] }
      final rows = (data is Map && data['data'] is List)
          ? data['data'] as List
          : <dynamic>[];

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
      final msg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Gagal mengambil detail pemeriksaan');
      throw Exception(msg);
    }
  }
}
