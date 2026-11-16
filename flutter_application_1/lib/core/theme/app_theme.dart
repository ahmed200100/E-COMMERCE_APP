import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _primary = Color(0xFF1E293B);
  static const _darkPrimary = Color(0xFFA5B4FC);
  static const _accent = Color(0xFFB89452);
  static const _canvas = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF172033);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _darkPrimary : _primary;
    final onPrimary = isDark ? const Color(0xFF171A34) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: isDark
          ? const Color(0xFF303955)
          : const Color(0xFFE9EEF5),
      onPrimaryContainer: isDark ? const Color(0xFFE2E7FF) : _primary,
      secondary: _accent,
      surface: isDark ? const Color(0xFF111827) : Colors.white,
      onSurface: isDark ? const Color(0xFFE5EAF2) : _ink,
      surfaceContainerHighest: isDark
          ? const Color(0xFF263244)
          : const Color(0xFFE8EDF3),
      outlineVariant: isDark
          ? const Color(0xFF3B475A)
          : const Color(0xFFDCE3EC),
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1220) : _canvas,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: .08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: rounded,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0B1220) : _canvas,
        foregroundColor: isDark ? scheme.onSurface : _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? scheme.onSurface : _ink,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: primary.withValues(alpha: isDark ? .22 : .10),
        elevation: 8,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        )),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: primary,
        textColor: onPrimary,
        smallSize: 8,
        largeSize: 18,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
