import 'package:dio/dio.dart';
import 'api_client.dart';

class RegistrationApi {
  final ApiClient _client;
  RegistrationApi(this._client);

  Future<Map<String, dynamic>> queueToday() async {
    try {
      final res = await _client.dio.get('/registrations/queue/today');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ?? e.message ?? 'Gagal';
      throw Exception(msg);
    }
  }

  /// POST /registrations/
  /// multipart:
  /// - surat_rujukan (file)
  /// - tanggal_antrian (YYYY-MM-DD)
  /// - jadwal_pemeriksaan_at (YYYY-MM-DD HH:mm:ss)
  Future<Map<String, dynamic>> createRegistration({
    required String tanggalAntrian,
    required String jadwalPemeriksaanAt,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'tanggal_antrian': tanggalAntrian,
        'jadwal_pemeriksaan_at': jadwalPemeriksaanAt,
        'surat_rujukan': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final res = await _client.dio.post(
        '/registrations/',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Gagal membuat pendaftaran';
      throw Exception(msg);
    }
  }
}
