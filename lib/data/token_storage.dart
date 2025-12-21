import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);
  Future<String?> getToken() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}
