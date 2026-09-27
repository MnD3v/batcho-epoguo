import 'package:flutter/material.dart';

/// Palette et thème « jeu » : couleurs vives, boutons en relief, police ronde.
abstract final class Duo {
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF58A700);
  static const greenLight = Color(0xFFD7FFB8);
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF1899D6);
  static const blueLight = Color(0xFFDDF4FF);
  static const gold = Color(0xFFFFC800);
  static const goldDark = Color(0xFFE5A800);
  static const orange = Color(0xFFFF9600);
  static const orangeDark = Color(0xFFE08600);
  static const red = Color(0xFFFF4B4B);
  static const redDark = Color(0xFFEA2B2B);
  static const redLight = Color(0xFFFFDFE0);
  static const border = Color(0xFFE5E5E5);
  static const gray = Color(0xFFAFAFAF);
  static const snow = Color(0xFFF7F7F7);
  static const text = Color(0xFF4B4B4B);
  static const textLight = Color(0xFF777777);

  static const font = 'PlusJakartaSans';

  static ThemeData theme() {
    final base = ThemeData(
      fontFamily: font,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: text,
    height: 1.2,
  );
  static const heading = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: text,
  );
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textLight,
    height: 1.4,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: gray,
    letterSpacing: 1,
  );
}
