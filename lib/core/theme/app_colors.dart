import 'package:flutter/material.dart';

/// Brand palette for the Tagme3a demo.
abstract final class AppColors {
  static const Color primary = Color(0xFF1F4BF5);
  static const Color primaryDark = Color(0xFF1233C7);
  static const Color primaryDeep = Color(0xFF0B1B5C);
  static const Color blueMid = Color(0xFF5B82FF);
  static const Color softBlue = Color(0xFFEDF2FF);
  static const Color softBlueStrong = Color(0xFFDDE7FF);

  static const Color accent = Color(0xFFC8F451);
  static const Color accentDeep = Color(0xFFAFE32B);
  static const Color accentSoft = Color(0xFFF3FDDD);

  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF0F1833);
  static const Color inkSoft = Color(0xFF3C4767);
  static const Color muted = Color(0xFF7B849D);
  static const Color line = Color(0xFFE6EAF3);
  static const Color lineStrong = Color(0xFFD8DEEB);

  static const Color success = Color(0xFF14986A);
  static const Color successSoft = Color(0xFFE7F8F0);
  static const Color warning = Color(0xFFE07A17);
  static const Color warningSoft = Color(0xFFFFF3E5);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFFECEC);
  static const Color gold = Color(0xFFFFC24B);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1D47F0), Color(0xFF2C63FF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1237D6), Color(0xFF1F4BF5), Color(0xFF2E66FF)],
  );
}
