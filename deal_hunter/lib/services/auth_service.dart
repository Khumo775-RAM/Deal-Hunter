import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final _api = ApiService();

  Future<void> register(
      String username, String email, String password) async {
    await _api.post(ApiConfig.register,
        body: {'username': username, 'email': email, 'password': password});
  }

  Future<void> login(String username, String password) async {
    final data = await _api.post(
      ApiConfig.login,
      body: {'username': username, 'password': password},
      formData: true,
    );
    await StorageService.saveToken(data['access_token'] as String);
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout, auth: true);
    } catch (_) {}
    await StorageService.clearToken();
  }

  Future<User> getMe() async {
    final data = await _api.get(ApiConfig.me, auth: true);
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<User> verifyEmail(String username, String code) async {
    final data = await _api.post(
      ApiConfig.verifyEmail,
      body: {'username': username, 'code': code},
    );
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<void> resendVerification(String username) async {
    await _api.post(
      ApiConfig.resendVerification,
      body: {'username': username},
    );
  }

  Future<void> deleteAccount() async {
    await _api.delete('/auth/account', auth: true);
    await StorageService.clearToken();
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      ApiConfig.forgotPassword,
      body: {'email': email},
    );
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    await _api.post(
      ApiConfig.resetPassword,
      body: {'email': email, 'code': code, 'new_password': newPassword},
    );
  }
}
