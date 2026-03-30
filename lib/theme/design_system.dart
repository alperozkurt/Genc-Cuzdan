import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color darkIndigo = Color(0xFF4F46E5);
  static const Color primarySlate = Color(0xFF1E293B);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color accentCoral = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF0F172A);
  static const Color gray = Color(0xFF64748B);
  static const Color lightGray = Color(0xFFF1F5F9);

  // Typography
  static TextStyle heading(
          {double size = 28, Color color = black, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.outfit(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: -0.5,
      );

  static TextStyle subheading(
          {double size = 18, Color color = black, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static TextStyle body(
          {double size = 14, Color color = gray, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  // Decorations
  static BoxDecoration premiumCard({Color? color, List<Color>? gradientColors}) {
    return BoxDecoration(
      color: color ?? white,
      gradient: gradientColors != null
          ? LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration glassCard({double opacity = 0.05}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    );
  }

  // Premium Dialog Helper
  static void showPremiumDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        contentPadding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(title, style: heading(size: 22)),
        content: content,
        actions: actions,
      ),
    );
  }
}
