import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // CIT Blue
        brightness: Brightness.light,
      ),
      // フォントテーマの設定
      textTheme: GoogleFonts.notoSansJpTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: GoogleFonts.notoSansJp(),
        hintStyle: GoogleFonts.notoSansJp(
          color: Colors.grey[600],
        ),
      ),
      // BottomNavigationBarのフォント
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // CIT Blue
        brightness: Brightness.dark,
      ),
      // フォントテーマの設定
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[800],
        labelStyle: GoogleFonts.notoSansJp(),
        hintStyle: GoogleFonts.notoSansJp(
          color: Colors.grey[400],
        ),
      ),
      // BottomNavigationBarのフォント
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        backgroundColor: Colors.grey[900],
      ),
      // カードのテーマ
      cardTheme: CardThemeData(
        color: Colors.grey[800],
        elevation: 2,
      ),
      // Scaffoldのテーマ
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }
}