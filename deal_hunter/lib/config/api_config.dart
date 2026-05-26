import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Your PC's local network IP (run `ipconfig` in PowerShell, look for IPv4).
  /// Only needed when running on a physical Android/iOS device.
  /// Example: '192.168.1.105'
  static const String _physicalDeviceIp = '192.168.137.1';

  /// Automatically picks the correct base URL per platform:
  ///  - Web / desktop (Windows, macOS, Linux) → 127.0.0.1
  ///  - Android emulator                      → 10.0.2.2  (maps to host loopback)
  ///  - Physical device                       → your PC's LAN IP (_physicalDeviceIp)
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) {
      if (_physicalDeviceIp.isNotEmpty) {
        return 'http://$_physicalDeviceIp:8000';
      }
      return 'http://10.0.2.2:8000'; // emulator fallback
    }
    return 'http://127.0.0.1:8000';
  }

  static const String deals    = '/deals/';
  static const String search   = '/search/';
  static const String track    = '/track/';
  static const String register           = '/auth/register';
  static const String login              = '/auth/login';
  static const String logout             = '/auth/logout';
  static const String me                 = '/auth/me';
  static const String verifyEmail        = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword     = '/auth/forgot-password';
  static const String resetPassword      = '/auth/reset-password';
}
