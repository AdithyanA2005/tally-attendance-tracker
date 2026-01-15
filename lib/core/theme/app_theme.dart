import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/calendar/data/models/session_model.dart';

class AppTheme {
  static final TextTheme _textTheme = GoogleFonts.outfitTextTheme();

  // Premium Minimalist Palette
  static const Color _primary = Color(
    0xFF2D3436,
  ); // Obsidian Grey (Primary Brand)
  static const Color _accent = Color(
    0xFF6C5CE7,
  ); // Royal Indigo (Sophisticated Accent)
  static const Color _backgroundLight = Color(0xFFFAFAFA); // Paper White
  static const Color _textDark = Color(0xFF2D3436);
  static const Color _textSub = Color(0xFF636E72); // Slate Grey

  static const Color _calmRed = Color(0xFFE17055); // Burnt Terra

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        surface: _backgroundLight,
        primary: _primary,
        secondary: _accent,
        tertiary: _textSub,
        error: _calmRed,
        onSurface: _textDark,
        onSurfaceVariant: _textSub,
      ),
      scaffoldBackgroundColor: _backgroundLight,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: _textTheme.apply(
        bodyColor: _textDark,
        displayColor: _textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(
          color: _textDark,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      iconTheme: const IconThemeData(color: _textDark),
      dividerTheme: DividerThemeData(
        color: _textSub.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        primary: Colors.white,
        secondary: _accent,
        tertiary: const Color(0xFFAAAAAA),
        error: _calmRed,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: _textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static const Map<AttendanceStatus, Color> statusColors = {
    AttendanceStatus.present: Color(0xFF27AE60), // Sage Green
    AttendanceStatus.absent: Color(0xFFC0392B), // Muted Red
    AttendanceStatus.cancelled: Colors.grey,
    AttendanceStatus.unmarked: Colors.black,
  };

  static const List<Color> subjectColors = [
    Color(0xFF2C3E50), // Midnight Blue
    Color(0xFF8E44AD), // Muted Purple
    Color(0xFF27AE60), // Sage Green
    Color(0xFFD35400), // Burnt Orange
    Color(0xFFC0392B), // Muted Red
    Color(0xFF16A085), // Muted Teal
    Color(0xFF2980B9), // Muted Blue
    Color(0xFFD81B60), // Deep Pink
  ];
}
