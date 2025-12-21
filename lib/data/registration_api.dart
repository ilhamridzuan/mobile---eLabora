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
}
