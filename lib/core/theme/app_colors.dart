import 'package:flutter/material.dart';

/// Centralized color palette for the AI Study Companion app.
/// Never hardcode colors in widgets — always reference [AppColors].
class AppColors {
  AppColors._();

  // Primary palette — Deep Indigo
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1642);
  static const Color accent = Color(0xFF448AFF);

  // Surfaces
  static const Color surface = Color(0xFFF5F5F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF8F9FC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Borders & Dividers
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Feature-specific
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color quizPurple = Color(0xFF8B5CF6);
  static const Color notesTeal = Color(0xFF14B8A6);
  static const Color plannerBlue = Color(0xFF0EA5E9);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Subject chip colors
  static const Map<String, Color> subjectColors = {
    'AI': Color(0xFF8B5CF6),
    'OOP': Color(0xFF0EA5E9),
    'DSA': Color(0xFF10B981),
    'DB': Color(0xFFF59E0B),
    'OS': Color(0xFFEF4444),
    'Networks': Color(0xFF14B8A6),
    'Math': Color(0xFFEC4899),
    'English': Color(0xFF6366F1),
  };

  /// Returns a color for a given subject, falling back to primary.
  static Color getSubjectColor(String subject) {
    return subjectColors[subject] ?? primary;
  }
}
