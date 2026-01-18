import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tally/core/data/models/session_model.dart';

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
      timePickerTheme: TimePickerThemeData(
        backgroundColor: _backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _primary
              : _primary.withValues(alpha: 0.05),
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : _primary,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? _primary : _textSub,
        ),
        dialHandColor: _primary,
        dialBackgroundColor: _primary.withValues(alpha: 0.05),
        dialTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : _textDark,
        ),
        entryModeIconColor: _primary,
        helpTextStyle: const TextStyle(color: _textSub, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _backgroundLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: _textSub,
          fontSize: 15,
          height: 1.5,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
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
        surfaceContainerHighest: const Color(
          0xFF2A2A2A,
        ), // Neutral gray instead of tinted
        surfaceContainer: const Color(0xFF252525),
        surfaceContainerLow: const Color(0xFF212121),
        surfaceContainerLowest: const Color(0xFF1A1A1A),
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
      timePickerTheme: TimePickerThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white.withValues(alpha: 0.05),
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF1E1E1E)
              : Colors.white,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFAAAAAA),
        ),
        dialHandColor: Colors.white,
        dialBackgroundColor: Colors.white.withValues(alpha: 0.05),
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF1E1E1E)
              : Colors.white,
        ),
        entryModeIconColor: Colors.white,
        helpTextStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFAAAAAA),
          fontSize: 15,
          height: 1.5,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static const Map<AttendanceStatus, Color> statusColors = {
    AttendanceStatus.present: const Color(0xFF27AE60), // Nephritis
    AttendanceStatus.absent: const Color(0xFFC0392B), // Pomegranate
    AttendanceStatus.cancelled: const Color(0xFF607D8B), // Blue Grey
    AttendanceStatus.scheduled: const Color(0xFF95A5A6), // Concrete
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
