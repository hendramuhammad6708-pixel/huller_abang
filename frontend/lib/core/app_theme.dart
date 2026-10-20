import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B4D3E);
  static const primaryLight = Color(0xFF2E7D5B);
  static const mint = Color(0xFFD7F5E3);
  static const mintText = Color(0xFF0F7A47);
  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1C2430);
  static const textMuted = Color(0xFF6B7684);
  static const border = Color(0xFFE5E9F0);
  static const blueSoft = Color(0xFFE4EEFF);
  static const blue = Color(0xFF3B6FD8);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      );
}
