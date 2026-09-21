import '../models/auth_models.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/token_store.dart';

class AuthRepository {
  AuthRepository({required this.apiClient, required this.tokenStore});

  final ApiClient apiClient;
  final TokenStore tokenStore;

  Future<AuthUser> login(String email, String password) async {
    final response =
        await apiClient.post('/auth/login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(response);
    await tokenStore.saveToken(authResponse.accessToken);
    return authResponse.user;
  }

  Future<void> logout() => tokenStore.clearToken();

  Future<bool> hasSession() => tokenStore.hasToken();

  Future<AuthUser?> restoreSession() async {
    if (!await hasSession()) return null;
    try {
      final response = await apiClient.get('/auth/me') as Map<String, dynamic>;
      return AuthUser.fromJson(response);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await logout();
      return null;
    }
  }
}
