import 'package:flutter/material.dart';

const _systemFont = '.AppleSystemUIFont';

/// Refined indigo accent — the app's single brand color across both themes.
const accentColor = Color(0xFF6366F1);

/// Shared corner radii so every card/sheet in the app reads as one system.
const cardRadius = 16.0;
const tileRadius = 11.0;
const chipRadius = 8.0;

/// A soft, low-spread shadow used on elevated surfaces (the popup shell,
/// section cards). Tuned separately per brightness so it stays subtle in
/// dark mode instead of turning into a gray halo.
List<BoxShadow> cardShadow(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFFF0F0F4),
  );
  return _buildTheme(scheme);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF232328),
    surfaceContainerHighest: const Color(0xFF2C2C33),
  );
  return _buildTheme(scheme);
}

ThemeData _buildTheme(ColorScheme scheme) {
  final isDark = scheme.brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _systemFont,
    // Transparent: the window's real background is the native
    // NSVisualEffectView blur set up in WindowController, not a flat
    // Flutter-painted color.
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: isDark ? const Color(0x0FFFFFFF) : const Color(0x08000000),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 18),
    textTheme: const TextTheme().apply(fontFamily: _systemFont),
  );
}
