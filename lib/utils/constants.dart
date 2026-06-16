import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF563AFF);
  static const Color secondary = Color(0xFF48C0B8);
  static const Color background = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF26233A);
  static const Color textSecondary = Color(0xFF8B8FA9);

  static const Color secondaryDark = Color(0xFF2E7D77);

  static const Gradient secondaryGradient = LinearGradient(
    colors: [
      Color(0xFF48C0B8),
      Color(0xFF2E7D77),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}