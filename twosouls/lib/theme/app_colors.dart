import 'package:flutter/material.dart';

class AppColors {
  // ── existing ────────────────────────────────────────────────────────────
  static const bgDark = Color(0xFF0B0F1F);
  static const surfaceDark = Color(0xFF11224D);
  static const primaryBlue = Color(0xFF2E6CD6);
  static const accentBlue = Color(0xFF9EC5FF);
  static const white = Color(0xFFFFFFFF);

  // ── profile / card ──────────────────────────────────────────────────────
  static const cardBg = Color(0xFF101C3F);
  static const cardBgDeep = Color(0xFF0A1330);
  static const panelBg = Color(0xFF101830);
  static const panelBorder = Color(0x33B44CFF);

  static const gold = Color(0xFFD4AF6A);
  static const goldDark = Color(0xFF8A6A2F);
  static const goldLight = Color(0xFFF0CC6E);

  static const purple = Color(0xFFB44CFF);
  static const purpleSoft = Color(0xFFE085FF);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9EC5FF);
  static const textMuted = Color(0xFF4A6080);

  // ── rarity ──────────────────────────────────────────────────────────────
  static const bronze = Color(0xFFCD7F32);
  static const silver = Color(0xFFB0BEC5);
  static const sapphire = Color(0xFF1E90FF);
  static const emerald = Color(0xFF50C878);
  static const platinum = Color(0xFFE0E6EC);
  static const rarityPurple = Color(0xFF9B30FF);

  // ── self / identity (your own card — never a rarity colour) ───────────
  static const selfAccent = Color(
    0xFF2DD4BF,
  ); // teal, distinct from every rarity tier
}
