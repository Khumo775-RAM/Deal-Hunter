import 'package:flutter/material.dart';

/// Semantic color tokens for the app.
/// Access via [BuildContext.colors] anywhere you have a context.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.accent,
    required this.accentMuted,
    required this.onAccent,
    required this.textPrimary,
    required this.textHigh,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textFaint,
    required this.accentSubtle,
    required this.accentBorder,
    required this.accentNavIndicator,
  });

  final Color background;
  final Color surface;

  /// Primary action / highlight colour.
  final Color accent;

  /// Soft, washed-out version of [accent].
  final Color accentMuted;

  /// Text / icon colour to use ON TOP of [accent] (e.g. button labels).
  final Color onAccent;

  final Color textPrimary;   // 100 %
  final Color textHigh;      // ≈ 70 %
  final Color textSecondary; // ≈ 50 %
  final Color textMuted;     // ≈ 38 %
  final Color textDisabled;  // ≈ 24 %
  final Color textFaint;     // ≈ 12 %

  final Color accentSubtle;
  final Color accentBorder;
  final Color accentNavIndicator;

  // ─── Purple – dark theme ──────────────────────────────────────────────────
  static const purple = AppColors(
    background:         Color(0xFF0F0F1A),
    surface:            Color(0xFF1A1A2E),
    accent:             Color(0xFF6C63FF),
    accentMuted:        Color(0xFF9B97C5),
    onAccent:           Color(0xFFFFFFFF),  // white text on purple button
    textPrimary:        Color(0xFFFFFFFF),
    textHigh:           Color(0xB3FFFFFF), // 70 %
    textSecondary:      Color(0x80FFFFFF), // 50 %
    textMuted:          Color(0x61FFFFFF), // 38 %
    textDisabled:       Color(0x3DFFFFFF), // 24 %
    textFaint:          Color(0x1FFFFFFF), // 12 %
    accentSubtle:       Color(0x266C63FF), // 15 %
    accentBorder:       Color(0x4D6C63FF), // 30 %
    accentNavIndicator: Color(0x336C63FF), // 20 %
  );

  // ─── Ember – light theme ──────────────────────────────────────────────────
  static const orange = AppColors(
    background:         Color(0xFFFDF7F2),  // cream white
    surface:            Color(0xFFFFFFFF),  // pure white cards
    accent:             Color(0xFFFFA252),  // warm orange
    accentMuted:        Color(0xFFFFD4B0),  // light peach
    onAccent:           Color(0xFF1F1F1F),  // dark text on orange buttons
    textPrimary:        Color(0xFF1F1F1F),  // near-black
    textHigh:           Color(0xB31F1F1F), // 70 %
    textSecondary:      Color(0x801F1F1F), // 50 %
    textMuted:          Color(0x611F1F1F), // 38 %
    textDisabled:       Color(0x3D1F1F1F), // 24 %
    textFaint:          Color(0x1F1F1F1F), // 12 %
    accentSubtle:       Color(0x26FFA252), // 15 %
    accentBorder:       Color(0x4DFFA252), // 30 %
    accentNavIndicator: Color(0x33FFA252), // 20 %
  );

  // ─── ThemeExtension boilerplate ───────────────────────────────────────────
  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? accent,
    Color? accentMuted,
    Color? onAccent,
    Color? textPrimary,
    Color? textHigh,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textFaint,
    Color? accentSubtle,
    Color? accentBorder,
    Color? accentNavIndicator,
  }) =>
      AppColors(
        background:         background         ?? this.background,
        surface:            surface            ?? this.surface,
        accent:             accent             ?? this.accent,
        accentMuted:        accentMuted        ?? this.accentMuted,
        onAccent:           onAccent           ?? this.onAccent,
        textPrimary:        textPrimary        ?? this.textPrimary,
        textHigh:           textHigh           ?? this.textHigh,
        textSecondary:      textSecondary      ?? this.textSecondary,
        textMuted:          textMuted          ?? this.textMuted,
        textDisabled:       textDisabled       ?? this.textDisabled,
        textFaint:          textFaint          ?? this.textFaint,
        accentSubtle:       accentSubtle       ?? this.accentSubtle,
        accentBorder:       accentBorder       ?? this.accentBorder,
        accentNavIndicator: accentNavIndicator ?? this.accentNavIndicator,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background:         Color.lerp(background,         other.background,         t)!,
      surface:            Color.lerp(surface,            other.surface,            t)!,
      accent:             Color.lerp(accent,             other.accent,             t)!,
      accentMuted:        Color.lerp(accentMuted,        other.accentMuted,        t)!,
      onAccent:           Color.lerp(onAccent,           other.onAccent,           t)!,
      textPrimary:        Color.lerp(textPrimary,        other.textPrimary,        t)!,
      textHigh:           Color.lerp(textHigh,           other.textHigh,           t)!,
      textSecondary:      Color.lerp(textSecondary,      other.textSecondary,      t)!,
      textMuted:          Color.lerp(textMuted,          other.textMuted,          t)!,
      textDisabled:       Color.lerp(textDisabled,       other.textDisabled,       t)!,
      textFaint:          Color.lerp(textFaint,          other.textFaint,          t)!,
      accentSubtle:       Color.lerp(accentSubtle,       other.accentSubtle,       t)!,
      accentBorder:       Color.lerp(accentBorder,       other.accentBorder,       t)!,
      accentNavIndicator: Color.lerp(accentNavIndicator, other.accentNavIndicator, t)!,
    );
  }
}

/// Convenience extension – use `context.colors.accent` anywhere.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
