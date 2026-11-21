import 'package:flutter/material.dart';

/// Paleta del blog: azul marino nocturno (como las portadas de videojuegos),
/// azul eléctrico para acciones y naranja "trofeo" para destacados y puntuaciones.
class AppColors {
  static const Color fondo = Color(0xFF0A1226);
  static const Color superficie = Color(0xFF111C36);
  static const Color superficieAlta = Color(0xFF18264A);
  static const Color borde = Color(0xFF263A66);

  static const Color texto = Color(0xFFEAF0FF);
  static const Color textoSuave = Color(0xFF93A6CC);

  static const Color azul = Color(0xFF2E8BFF);
  static const Color azulOscuro = Color(0xFF1457B8);
  static const Color naranja = Color(0xFFFF9A1F);
  static const Color naranjaOscuro = Color(0xFFE0700A);
  static const Color rojo = Color(0xFFFF5470);

  /// Color de identificación para cada rol.
  static Color colorRol(int rol) {
    switch (rol) {
      case 1:
        return naranja; // Administrador
      case 2:
        return azul; // Autor
      default:
        return const Color(0xFF5B6F99); // Lector
    }
  }
}

/// Estilos de texto reutilizables para títulos de portada y encabezados de sección.
class AppText {
  /// Titular grande de portada (negrita extrema, como en las revistas de juegos).
  static TextStyle titular(double tamano, {Color color = AppColors.texto}) => TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: 0.3,
        color: color,
      );

  /// Encabezado de sección: mayúsculas anchas, como "ÚLTIMAS NOTICIAS".
  static const TextStyle seccion = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.6,
    color: AppColors.texto,
  );

  static const TextStyle meta = TextStyle(
    fontSize: 12,
    color: AppColors.textoSuave,
  );
}

class AppTheme {
  static ThemeData get oscuro {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.azul,
      onPrimary: Colors.white,
      secondary: AppColors.naranja,
      onSecondary: const Color(0xFF1A1000),
      error: AppColors.rojo,
      surface: AppColors.fondo,
      onSurface: AppColors.texto,
      onSurfaceVariant: AppColors.textoSuave,
      outline: AppColors.borde,
      outlineVariant: AppColors.borde,
      surfaceContainerLowest: AppColors.fondo,
      surfaceContainerLow: AppColors.superficie,
      surfaceContainer: AppColors.superficie,
      surfaceContainerHigh: AppColors.superficieAlta,
      surfaceContainerHighest: AppColors.superficieAlta,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borde),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.texto,
        displayColor: AppColors.texto,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.texto,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.fondo,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieAlta,
        labelStyle: const TextStyle(color: AppColors.textoSuave),
        hintStyle: const TextStyle(color: AppColors.textoSuave),
        prefixIconColor: AppColors.textoSuave,
        suffixIconColor: AppColors.textoSuave,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: AppColors.azul, width: 1.6),
        ),
        errorBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: AppColors.rojo),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.superficieAlta,
          disabledForegroundColor: AppColors.textoSuave,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.texto,
          side: const BorderSide(color: AppColors.borde),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azul,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.naranja,
        foregroundColor: const Color(0xFF1A1000),
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.superficieAlta,
        selectedColor: AppColors.azul,
        disabledColor: AppColors.superficieAlta,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.borde),
        labelStyle: const TextStyle(color: AppColors.texto, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borde, space: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textoSuave,
        textColor: AppColors.texto,
        selectedColor: AppColors.azul,
        selectedTileColor: Color(0x1F2E8BFF),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.superficieAlta,
        contentTextStyle: const TextStyle(color: AppColors.texto),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.azul),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.naranja
              : AppColors.textoSuave,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? const Color(0x66FF9A1F)
              : AppColors.superficieAlta,
        ),
      ),
    );
  }
}
