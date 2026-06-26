import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EgcColors {
  static const primary     = Color(0xFFEA580C);
  static const primaryDark = Color(0xFFC2410C);
  static const primaryBg   = Color(0xFFFFF7ED);
  static const primaryMid  = Color(0xFFFED7AA);
  static const ok          = Color(0xFF15803D);
  static const okBg        = Color(0xFFF0FDF4);
  static const okLine      = Color(0xFFBBF7D0);
  static const err         = Color(0xFFB91C1C);
  static const errBg       = Color(0xFFFEF2F2);
  static const blue        = Color(0xFF2563EB);
  static const blueBg      = Color(0xFFEFF6FF);
  static const gold        = Color(0xFFB45309);
  static const goldBg      = Color(0xFFFFFBEB);
  static const ink         = Color(0xFF0F1117);
  static const ink2        = Color(0xFF3D4152);
  static const ink3        = Color(0xFF8B8FA8);
  static const bg          = Color(0xFFF5F5F9);
  static const bg2         = Color(0xFFFFFFFF);
  static const bg3         = Color(0xFFEEF0F6);
  static const line        = Color(0xFFE4E4EF);
  static const line2       = Color(0xFFD0D0E0);
}

class EgcRadius {
  static const sm  = Radius.circular(8);
  static const md  = Radius.circular(12);
  static const lg  = Radius.circular(16);
  static const xl  = Radius.circular(20);
  static final smBorder = BorderRadius.circular(8);
  static final mdBorder = BorderRadius.circular(12);
  static final lgBorder = BorderRadius.circular(16);
  static final xlBorder = BorderRadius.circular(20);
  static final pill     = BorderRadius.circular(100);
}

class EgcTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EgcColors.primary,
      primary: EgcColors.primary,
      surface: EgcColors.bg2,
      error: EgcColors.err,
    ),
    scaffoldBackgroundColor: EgcColors.bg,
    textTheme: GoogleFonts.dmSansTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: EgcColors.bg2,
      foregroundColor: EgcColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.w800,
        color: EgcColors.ink, letterSpacing: -0.3,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: EgcColors.bg2,
      selectedItemColor: EgcColors.primary,
      unselectedItemColor: EgcColors.ink3,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: EgcColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: EgcColors.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EgcColors.line, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EgcColors.line, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EgcColors.primary, width: 1.5)),
    ),
    cardTheme: CardTheme(
      color: EgcColors.bg2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: EgcColors.line, width: 1.5)),
    ),
    dividerTheme: const DividerThemeData(color: EgcColors.line, thickness: 1, space: 0),
    splashFactory: NoSplash.splashFactory,
  );
}
