import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  // Stores the email of an unverified account so the login screen can
  // pass it to VerifyEmailScreen without making an extra API call.
  String? _pendingUnverifiedEmail;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingUnverifiedUser => _pendingUnverifiedEmail;
  bool get isLoggedIn => StorageService.isLoggedIn;

  final _auth = AuthService();

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      await _auth.login(username, password);
      _user = await _auth.getMe();
      _pendingUnverifiedEmail = null;
      _setLoading(false);
      return true;
    } catch (e) {
      final msg = e.toString();
      _error = msg;
      // Capture the username so VerifyEmailScreen can show the masked email.
      if (msg.contains('EMAIL_NOT_VERIFIED')) {
        _pendingUnverifiedEmail = username;
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
      String username, String email, String password) async {
    _setLoading(true);
    try {
      await _auth.register(username, email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      await _auth.deleteAccount();
      _user = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Toggle email notifications on/off. Updates local state optimistically
  /// and rolls back if the API call fails.
  Future<bool> toggleNotifications(bool enabled) async {
    if (_user == null) return false;
    final previous = _user!.emailNotifications;
    _user = _user!.copyWith(emailNotifications: enabled);
    notifyListeners();

    try {
      final api = ApiService();
      final data = await api.patch(
        '/auth/notifications',
        body: {'enabled': enabled},
        auth: true,
      ) as Map<String, dynamic>;
      _user = User.fromJson(data);
      notifyListeners();
      return true;
    } catch (e) {
      // Roll back on failure.
      _user = _user!.copyWith(emailNotifications: previous);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
