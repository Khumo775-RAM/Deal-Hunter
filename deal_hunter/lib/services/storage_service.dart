import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static const String _tokenKey    = 'auth_token';
  static const String _currencyKey = 'currency';
  static const String _themeKey    = 'app_theme';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async =>
      _prefs.setString(_tokenKey, token);

  static String? getToken() => _prefs.getString(_tokenKey);

  static Future<void> clearToken() async => _prefs.remove(_tokenKey);

  static bool get isLoggedIn => getToken() != null;

  static Future<void> saveCurrency(String currency) async =>
      _prefs.setString(_currencyKey, currency);

  static String getCurrency() => _prefs.getString(_currencyKey) ?? 'USD';

  static Future<void> saveTheme(String theme) async =>
      _prefs.setString(_themeKey, theme);

  static String getTheme() => _prefs.getString(_themeKey) ?? 'purple';
}
