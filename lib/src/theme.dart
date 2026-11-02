import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Spice {
  static const night = Color(0xFF0A0F1E);
  static const black = Color(0xFF0E0A07);
  static const surface = Color(0xFF1A120C);
  static const card = Color(0xFF241911);
  static const brown = Color(0xFF3A2718);
  static const orange = Color(0xFFE8751A);
  static const amber = Color(0xFFFFB547);
  static const sand = Color(0xFFE9D7B8);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: orange,
      secondary: amber,
      surface: surface,
      onSurface: sand,
      surfaceContainerHighest: brown,
      surfaceContainer: card,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: sand, displayColor: sand),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()}),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: sand,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: amber),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: brown),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: night.withValues(alpha: 0.92),
        indicatorColor: orange.withValues(alpha: 0.25),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: orange.withValues(alpha: 0.3),
        side: const BorderSide(color: brown),
      ),
    );
  }

  static Color poiColor(String type) => switch (type) {
        'testing-station' => const Color(0xFFE8751A),
        'wreck' => const Color(0xFF8FB3D9),
        'cave' => const Color(0xFFB48EE0),
        'large-spice-field' => const Color(0xFFFF4D2E),
        'taxi-service' => const Color(0xFF6FD38A),
        'titanium' => const Color(0xFFC9D1D9),
        'stravidium' => const Color(0xFF4FD1D9),
        _ => amber,
      };

  static IconData poiIcon(String type) => switch (type) {
        'testing-station' => Icons.science,
        'wreck' => Icons.sailing,
        'cave' => Icons.landscape,
        'large-spice-field' => Icons.local_fire_department,
        'taxi-service' => Icons.flight,
        'titanium' => Icons.hexagon,
        'stravidium' => Icons.diamond,
        _ => Icons.place,
      };

  static Color tierColor(String? tier) => switch (tier) {
        'S' => const Color(0xFFFFC94A), // legendary gold
        'A' => const Color(0xFFC77DFF), // epic purple
        'B' => const Color(0xFF4FA3FF), // rare blue
        'C' => const Color(0xFF7BD88F), // uncommon green
        _ => brown,
      };
}
