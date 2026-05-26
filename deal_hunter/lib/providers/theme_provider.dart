import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _isOrange = StorageService.getTheme() == 'orange';
  }

  bool _isOrange = false;
  bool get isOrange => _isOrange;

  AppColors get colors => _isOrange ? AppColors.orange : AppColors.purple;

  ThemeData get themeData {
    if (_isOrange) {
      // ── Ember: light theme ─────────────────────────────────────────────────
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary:   Color(0xFFFFA252),
          onPrimary: Color(0xFF1F1F1F),
          secondary: Color(0xFF4CAF50),
          surface:   Color(0xFFFFFFFF),
          onSurface: Color(0xFF1F1F1F),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF7F2),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Color(0x801F1F1F), fontSize: 11),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1F1F1F)),
        ),
        extensions: [AppColors.orange],
      );
    } else {
      // ── Purple: dark theme ─────────────────────────────────────────────────
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF6C63FF),
          secondary: Color(0xFF4CAF50),
          surface:   Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        extensions: [AppColors.purple],
      );
    }
  }

  Future<void> setOrange(bool value) async {
    if (_isOrange == value) return;
    _isOrange = value;
    await StorageService.saveTheme(value ? 'orange' : 'purple');
    notifyListeners();
  }
}
