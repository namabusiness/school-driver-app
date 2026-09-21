import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'school_erp_driver_access_token';
  final FlutterSecureStorage storage;

  Future<void> saveToken(String token) =>
      storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => storage.read(key: _tokenKey);

  Future<void> clearToken() => storage.delete(key: _tokenKey);

  Future<bool> hasToken() async => (await getToken()) != null;
}
