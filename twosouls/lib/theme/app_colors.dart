import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppColors — 2Souls design system
//
// Palette pixel-matched to the logo: deep navy night sky, a royal-blue
// gradient inside the emblem, and moonlight white for the figure/text/stars.
// Every colour has a purpose:
//
//   bgDark / bgDeep  — page backgrounds, darkest layer
//   surface          — raised panels, cards, sheets (not match cards)
//   panelBg          — inner sections, input fields
//   panelBorder      — subtle borders between elements
//
//   accent           — primary interactive colour (logo's royal blue, brightened
//                      slightly for UI legibility on dark backgrounds)
//   accentSoft       — the logo's exact royal blue, for secondary actions
//   accentGlow       — for glows/shadows on focused/primary elements
//
//   flow1-4          — the "flowing water" gradient stops used on headers,
//                      dividers, shimmer effects: logo bg → logo's deep blue
//                      → mid blue → logo's bright royal blue
//
//   textPrimary      — main readable text (near-white, logo white)
//   textSecondary    — supporting/label text (muted blue-white)
//   textMuted        — placeholder text
//
//   gold / rarity*   — tier colours for match cards ONLY. These are
//                      deliberately kept outside the brand palette so rare
//                      cards visually "pop" — never use them for generic
//                      chrome (buttons, borders, icons); use accent instead.
//   success / danger — status colours, also deliberately brand-independent.
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF080B1A); // deepest navy — page bg
  static const Color bgDeep = Color(0xFF1B1D46); // exact logo background
  static const Color surface = Color(0xFF11132E); // raised panels/sheets
  static const Color panelBg = Color(0xFF161A3D); // input fields, inner panels
  static const Color panelBorder = Color(0xFF232A5C); // subtle borders

  // ── Accent — the logo's royal blue ─────────────────────────────────────────
  static const Color accent = Color(0xFF4C86D9); // primary CTA, links
  static const Color accentSoft = Color(0xFF2864B4); // exact logo royal blue
  static const Color accentGlow = Color(0x334C86D9); // shadows/glows

  // ── Flow gradient colours (logo emblem gradient) ───────────────────────────
  static const Color flow1 = Color(0xFF1B1D46); // logo background
  static const Color flow2 = Color(0xFF1E2864); // logo emblem — deep end
  static const Color flow3 = Color(0xFF234E96); // logo emblem — mid tone
  static const Color flow4 = Color(0xFF2864B4); // logo emblem — bright end

  // ── Highlights ─────────────────────────────────────────────────────────────
  static const Color moonlight = Color(
    0xFFF2F6FF,
  ); // brightest highlight (logo white)
  static const Color starWhite = Color(
    0xFFD8E6FA,
  ); // star/shimmer colour (logo glow)
  static const Color tealSheen = Color(
    0xFF2ABFBF,
  ); // self-card accent — status colour, brand-independent by design

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF2F6FF); // main text
  static const Color textSecondary = Color(0xFF8FA3D9); // labels, subtitles
  static const Color textMuted = Color(0xFF4A5A94); // placeholders

  // ── Status — deliberately brand-independent ────────────────────────────────
  static const Color success = Color(0xFF2ABFBF); // accept / green actions
  static const Color danger = Color(0xFFE05B5B); // deny / error

  // ── Rarity tier colours — used ONLY on match cards ────────────────────────
  // These are deliberately kept vibrant so cards "pop" against the navy bg.
  // NEVER use these for generic buttons/icons/chrome — use accent for that.
  static const Color gold = Color(0xFFD4AF6A);
  static const Color emerald = Color(0xFF50C878);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFA8A9AD);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color rarityPurple = Color(0xFFB44CFF); // Royal tier
  static const Color purple = Color(0xFFB44CFF); // alias — rarity use only

  // ── Self card accent (teal) ────────────────────────────────────────────────
  static const Color selfAccent = Color(0xFF2ABFBF);

  // ── Legacy aliases ─────────────────────────────────────────────────────────
  static const Color purpleSoft = Color(
    0xFF8A2FCC,
  ); // softer royal/purple — rarity use only
  static const Color goldLight = Color(
    0xFFE8C97A,
  ); // lighter gold — rarity use only
  static const Color cardBg = surface;
  static const Color surfaceDark = panelBg;
}

// ── Flow gradient — the signature multi-stop gradient used on headers,
//    diagonal splits, and any "sky" background element. Matches the logo's
//    own emblem gradient exactly.
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
