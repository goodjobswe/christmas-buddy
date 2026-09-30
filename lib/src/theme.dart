import 'package:flutter/material.dart';

const christmasRed = Color(0xFFD6001C);
const nightBlue = Color(0xFF14224F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: christmasRed,
    brightness: Brightness.light,
  ).copyWith(
    primary: christmasRed,
    onPrimary: Colors.white,
    secondary: const Color(0xFF2E8B3A),
    onSecondary: Colors.white,
    surface: const Color(0xFFFCF8F5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'OpenSans',
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: christmasRed,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Rochester',
        fontSize: 30,
        color: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: christmasRed,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: 'OpenSans', fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: christmasRed,
      foregroundColor: Colors.white,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: christmasRed,
      thumbColor: christmasRed,
      inactiveTrackColor: Color(0x44D6001C),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? christmasRed : null,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? christmasRed : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      textStyle: TextStyle(fontFamily: 'OpenSans', fontSize: 15, color: Colors.black87),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
