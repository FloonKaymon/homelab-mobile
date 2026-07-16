import 'package:flutter/material.dart';

import '../models/modulabs_module.dart';

/// Color palette ported from the homelab-frontend's DaisyUI "night" theme
/// (see homelab-frontend/src/app/App.tsx `data-theme="night"`), so the
/// mobile app reads as the same product as the web dashboard.
class AppColors {
  AppColors._();

  // Layered dark surfaces: 300 (nav/deepest) -> 200 (page bg) -> 100 (cards).
  static const base100 = Color(0xFF0F172A);
  static const base200 = Color(0xFF0C1425);
  static const base300 = Color(0xFF0A1120);
  static const baseContent = Color(0xFFC9CBD0);

  static const primary = Color(0xFF3ABDF7);
  static const primaryContent = Color(0xFF010D15);
  static const secondary = Color(0xFF818CF8);
  static const secondaryContent = Color(0xFF060715);
  static const accent = Color(0xFFF471B5);
  static const accentContent = Color(0xFF14040C);
  static const neutral = Color(0xFF1E293B);

  static const info = Color(0xFF0CA5E9);
  static const success = Color(0xFF2FD4BF);
  static const successContent = Color(0xFF01100D);
  static const warning = Color(0xFFF4BF51);
  static const warningContent = Color(0xFF140D02);
  static const error = Color(0xFFFB7085);
  static const errorContent = Color(0xFF150406);

  static Color faint(double opacity) => baseContent.withValues(alpha: opacity);
}

/// Shared label/color/icon mapping for module run status, used by both the
/// dashboard overview and the modules list so the two stay in sync.
(String, Color, IconData) statusVisuals(ModuleRunStatus status) {
  return switch (status) {
    ModuleRunStatus.active => ('Active', AppColors.success, Icons.check_circle),
    ModuleRunStatus.inactive => ('Stopped', AppColors.faint(0.45), Icons.pause_circle),
    ModuleRunStatus.installing => ('Installing', AppColors.warning, Icons.hourglass_top),
    ModuleRunStatus.error => ('Error', AppColors.error, Icons.error),
    ModuleRunStatus.unknown => ('Unknown', AppColors.faint(0.3), Icons.help_outline),
  };
}

/// "Modulabs" wordmark rendered with the same primary-to-accent gradient
/// used for the brand heading in the web sidebar (`from-primary to-accent`).
class ModulabsWordmark extends StatelessWidget {
  final double fontSize;
  final String text;

  const ModulabsWordmark({super.key, this.fontSize = 28, this.text = 'Modulabs'});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.primary, AppColors.accent],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

ThemeData buildModulabsTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.primaryContent,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryContent,
    tertiary: AppColors.accent,
    onTertiary: AppColors.accentContent,
    error: AppColors.error,
    onError: AppColors.errorContent,
    surface: AppColors.base100,
    onSurface: AppColors.baseContent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.base200,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.base300,
      foregroundColor: AppColors.baseContent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: AppColors.baseContent,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      iconTheme: IconThemeData(color: AppColors.faint(0.8)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.base300,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.faint(0.45),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    dividerColor: AppColors.faint(0.08),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w900, color: AppColors.baseContent),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.baseContent),
      titleMedium: TextStyle(fontWeight: FontWeight.bold, color: AppColors.baseContent),
      bodyMedium: TextStyle(color: AppColors.baseContent),
      bodySmall: TextStyle(color: Color(0xB3C9CBD0)),
    ),
    iconTheme: IconThemeData(color: AppColors.faint(0.8)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryContent,
        disabledBackgroundColor: AppColors.faint(0.12),
        disabledForegroundColor: AppColors.faint(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.base300,
      hintStyle: TextStyle(color: AppColors.faint(0.35)),
      labelStyle: TextStyle(color: AppColors.faint(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.base100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral,
      contentTextStyle: const TextStyle(color: AppColors.baseContent),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
