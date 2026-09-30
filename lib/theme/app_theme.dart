import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6C63FF);
  static const _secondaryColor = Color(0xFF03DAC6);

  static ThemeData getTheme(String mode) {
    switch (mode) {
      case 'oled':
        return oledTheme;
      case 'light':
        return lightTheme;
      case 'dark':
      default:
        return darkTheme;
    }
  }

  /// Standard dark theme (Navy / Slate dark)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: const Color(0xFF1E1E2E),
        onSurface: Colors.white,
        outline: Colors.white24,
      ),
      scaffoldBackgroundColor: const Color(0xFF11111B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF11111B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A3E),
        selectedColor: _primaryColor.withAlpha(55),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: const BorderSide(color: Colors.white10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryColor,
        inactiveTrackColor: _primaryColor.withAlpha(40),
        thumbColor: _primaryColor,
        overlayColor: _primaryColor.withAlpha(30),
        valueIndicatorColor: _primaryColor,
        valueIndicatorTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryColor,
        circularTrackColor: Colors.white12,
        linearTrackColor: Colors.white12,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white10,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Colors.white38),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _primaryColor : Colors.white12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A3E),
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        bodyMedium:
            TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
        bodySmall:
            TextStyle(fontSize: 11, color: Colors.white54, height: 1.4),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white),
      ),
    );
  }

  /// Pure Pitch Black OLED theme for maximum battery saving on AMOLED displays
  static ThemeData get oledTheme {
    const oledPrimary = Color(0xFF7E76FF);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: oledPrimary,
        secondary: _secondaryColor,
        surface: const Color(0xFF0C0C10),
        onSurface: Colors.white,
        outline: Colors.white24,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0C0C10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF22222C)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oledPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: oledPrimary,
          side: const BorderSide(color: oledPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF16161E),
        selectedColor: oledPrimary.withAlpha(55),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: const BorderSide(color: Color(0xFF262634)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: oledPrimary,
        inactiveTrackColor: oledPrimary.withAlpha(40),
        thumbColor: oledPrimary,
        overlayColor: oledPrimary.withAlpha(30),
        valueIndicatorColor: oledPrimary,
        valueIndicatorTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: oledPrimary,
        circularTrackColor: Colors.white12,
        linearTrackColor: Colors.white12,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF20202A),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Colors.white38),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? oledPrimary : Colors.white12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF16161E),
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        bodyMedium:
            TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
        bodySmall:
            TextStyle(fontSize: 11, color: Colors.white54, height: 1.4),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white),
      ),
    );
  }

  /// Clean modern Light theme
  static ThemeData get lightTheme {
    const lightPrimary = Color(0xFF5B52E0);
    const lightSecondary = Color(0xFF00A896);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: Colors.white,
        onSurface: const Color(0xFF1E202B),
        outline: const Color(0xFFE2E4EB),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F5FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F5FB),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1E202B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E202B),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8EAF2)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEEFF8),
        selectedColor: lightPrimary.withAlpha(40),
        labelStyle:
            const TextStyle(color: Color(0xFF2E3142), fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: const BorderSide(color: Color(0xFFDCDEEC)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        checkmarkColor: lightPrimary,
        showCheckmark: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: lightPrimary,
        inactiveTrackColor: lightPrimary.withAlpha(40),
        thumbColor: lightPrimary,
        overlayColor: lightPrimary.withAlpha(30),
        valueIndicatorColor: lightPrimary,
        valueIndicatorTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPrimary,
        circularTrackColor: Color(0xFFE0E2F0),
        linearTrackColor: Color(0xFFE0E2F0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8EAF0),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF9EA3B8)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? lightPrimary
                : const Color(0xFFD8DAE8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2D3D),
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
            fontSize: 15, color: Color(0xFF1E202B), height: 1.5),
        bodyMedium: TextStyle(
            fontSize: 13, color: Color(0xFF5A5D72), height: 1.5),
        bodySmall: TextStyle(
            fontSize: 11, color: Color(0xFF8589A2), height: 1.4),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E202B)),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E202B)),
      ),
    );
  }
}
