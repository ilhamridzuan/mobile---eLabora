import 'api_client.dart';

class QueueApi {
  final ApiClient _client;
  QueueApi(this._client);

  /// GET /queue/today
  /// Response:
  /// { tanggal: "YYYY-MM-DD", data: [ {...}, ... ] }
  Future<Map<String, dynamic>> today() async {
    final res = await _client.dio.get('/queue/today');
    final map = (res.data is Map)
        ? Map<String, dynamic>.from(res.data)
        : <String, dynamic>{};

    final tanggal = (map['tanggal'] ?? '').toString();
    final dataList = (map['data'] is List) ? (map['data'] as List) : <dynamic>[];

    final items = dataList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return {'tanggal': tanggal, 'data': items};
  }

  /// GET /queue/stats
  /// Response:
  /// { stats: {...}, tanggal: "YYYY-MM-DD" }
  Future<Map<String, dynamic>> stats() async {
    final res = await _client.dio.get('/queue/stats');
    final map = (res.data is Map)
        ? Map<String, dynamic>.from(res.data)
        : <String, dynamic>{};

    final tanggal = (map['tanggal'] ?? '').toString();
    final stats = (map['stats'] is Map)
        ? Map<String, dynamic>.from(map['stats'])
        : <String, dynamic>{};

    return {'tanggal': tanggal, 'stats': stats};
  }
}
