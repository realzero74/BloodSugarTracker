import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4A90E2);
  static const Color background = Color(0xFFF4F7F6);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF888888);
  static const Color dividerColor = Color(0xFFF0F0F0);

  // Tag Colors
  static const Color tagFastingText = Color(0xFF2980B9);
  static const Color tagFastingBg = Color(0xFFEBF5FB);
  static const Color chartFasting = Color(0xFF3498DB);

  static const Color tagExerciseText = Color(0xFF27AE60);
  static const Color tagExerciseBg = Color(0xFFEAFAF1);
  static const Color chartExercise = Color(0xFF2ECC71);

  static const Color tagBedtimeText = Color(0xFF8E44AD);
  static const Color tagBedtimeBg = Color(0xFFF4ECF7);
  static const Color chartBedtime = Color(0xFF9B59B6);

  static const Color tagExceptionText = Color(0xFFD35400);
  static const Color tagExceptionBg = Color(0xFFFBEEE6);

  // Legacy Tag Colors (하위 호환)
  static const Color tagPremealText = Color(0xFF16A085);
  static const Color tagPremealBg = Color(0xFFE8F8F5);
  static const Color chartPremeal = Color(0xFF1ABC9C);

  static const Color tagPostmealText = Color(0xFFD68910);
  static const Color tagPostmealBg = Color(0xFFFEF4E6);
  static const Color chartPostmeal = Color(0xFFF5A623);

  // Average Line Color
  static const Color chartAverage = Color(0xFFE74C3C);

  static Color getTagTextColor(String? tag) {
    switch (tag) {
      case '공복':
        return tagFastingText;
      case '운동후':
        return tagExerciseText;
      case '취침전':
        return tagBedtimeText;
      case '예외':
        return tagExceptionText;
      case '식전':
        return tagPremealText;
      case '식후':
        return tagPostmealText;
      default:
        return textSecondary;
    }
  }

  static Color getTagBgColor(String? tag) {
    switch (tag) {
      case '공복':
        return tagFastingBg;
      case '운동후':
        return tagExerciseBg;
      case '취침전':
        return tagBedtimeBg;
      case '예외':
        return tagExceptionBg;
      case '식전':
        return tagPremealBg;
      case '식후':
        return tagPostmealBg;
      default:
        return const Color(0xFFEEEEEE);
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 4,
      ),
    );
  }
}
