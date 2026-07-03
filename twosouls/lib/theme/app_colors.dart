import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppColors — 2Souls design system
//
// Palette inspired by the logo: deep navy night sky, soft moonlight whites,
// flowing water blues and teals. Every colour has a purpose:
//
//   bgDark / bgDeep  — page backgrounds, darkest layer
//   surface          — raised panels, cards, sheets (not match cards)
//   panelBg          — inner sections, input fields
//   panelBorder      — subtle borders between elements
//
//   accent           — primary interactive colour (moonlit blue-white)
//   accentSoft       — softer accent for secondary actions
//   accentGlow       — for glows/shadows on focused elements
//
//   flow1-4          — the "flowing water" gradient stops used on headers,
//                      dividers, shimmer effects: deep navy → cobalt → teal
//
//   textPrimary      — main readable text (near-white)
//   textSecondary    — supporting/label text (muted blue-white)
//   textMuted        — placeholder text
//
//   gold             — kept for the rarity system (match cards only)
//   rarity*          — tier colours for match cards only, unchanged
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF080D1F); // deepest navy — page bg
  static const Color bgDeep = Color(0xFF0D1033); // logo bg colour
  static const Color surface = Color(0xFF111A3A); // raised panels/sheets
  static const Color panelBg = Color(0xFF162040); // input fields, inner panels
  static const Color panelBorder = Color(0xFF1E2D5A); // subtle borders

  // ── Accent — moonlit blue/white ────────────────────────────────────────────
  static const Color accent = Color(0xFF6B9FFF); // primary CTA, links
  static const Color accentSoft = Color(0xFF4A7AE8); // secondary actions
  static const Color accentGlow = Color(0x334A7AE8); // shadows/glows

  // ── Flow gradient colours (water/constellation feel) ──────────────────────
  static const Color flow1 = Color(0xFF0D1033); // deep navy
  static const Color flow2 = Color(0xFF112355); // cobalt
  static const Color flow3 = Color(0xFF1A3A7A); // mid blue
  static const Color flow4 = Color(0xFF1E5C8A); // ocean teal-blue

  // ── Highlights ─────────────────────────────────────────────────────────────
  static const Color moonlight = Color(0xFFE8EFFF); // brightest highlight
  static const Color starWhite = Color(0xFFCDD9FF); // star/shimmer colour
  static const Color tealSheen = Color(0xFF2ABFBF); // self-card teal accent

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8EFFF); // main text
  static const Color textSecondary = Color(0xFF8BA4D4); // labels, subtitles
  static const Color textMuted = Color(0xFF4A6090); // placeholders

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ABFBF); // accept / green actions
  static const Color danger = Color(0xFFE05B5B); // deny / error

  // ── Rarity tier colours — used ONLY on match cards ────────────────────────
  // These are deliberately kept vibrant so cards "pop" against the navy bg.
  static const Color gold = Color(0xFFD4AF6A);
  static const Color emerald = Color(0xFF50C878);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFA8A9AD);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color rarityPurple = Color(0xFFB44CFF); // Royal tier
  static const Color purple = Color(0xFFB44CFF); // alias

  // ── Self card accent (teal) ────────────────────────────────────────────────
  static const Color selfAccent = Color(0xFF2ABFBF);

  // ── Legacy aliases ─────────────────────────────────────────────────────────
  static const Color purpleSoft = Color(0xFF8A2FCC); // softer royal/purple
  static const Color goldLight = Color(0xFFE8C97A); // lighter gold
  static const Color cardBg = surface;
  static const Color surfaceDark = panelBg;
}

// ── Flow gradient — the signature multi-stop gradient used on headers,
//    diagonal splits, and any "sky/water" background element.
const kFlowGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.flow1, AppColors.flow2, AppColors.flow3, AppColors.flow4],
  stops: [0.0, 0.35, 0.7, 1.0],
);

const kFlowGradientVertical = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.flow1, AppColors.flow2, AppColors.flow3],
  stops: [0.0, 0.5, 1.0],
);
