// ---------------------------------------------------------------------------
// AdConfig
//
// Single source of truth for all AdMob IDs.
// RIGHT NOW: Google's official test IDs are used — these show real AdMob
// test ads without requiring a real account or real traffic.
//
// TO GO LIVE: replace the values below with your real IDs from the
// AdMob dashboard (admob.google.com). Nothing else in the codebase needs
// to change — all ad widgets import only this file for their IDs.
//
// Android and iOS have separate App IDs and separate Ad Unit IDs.
// The App IDs live in the platform files (AndroidManifest.xml /
// Info.plist) — see AdManager.initialize() below for how they're set.
// ---------------------------------------------------------------------------

class AdConfig {
  AdConfig._();

  // ── App IDs (go in platform files, not in Dart — set in initialize()) ──
  static const String androidAppId  = 'ca-app-pub-3940256099942544~3347511713'; // TEST
  static const String iosAppId      = 'ca-app-pub-3940256099942544~1458002511'; // TEST
  // TODO LIVE: replace with ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX from AdMob dashboard

  // ── Banner ad unit IDs ───────────────────────────────────────────────────
  static const String androidBannerAdUnit = 'ca-app-pub-3940256099942544/6300978111'; // TEST
  static const String iosBannerAdUnit     = 'ca-app-pub-3940256099942544/2934735716'; // TEST
  // TODO LIVE: replace with your real banner unit IDs

  // ── Interstitial ad unit IDs ─────────────────────────────────────────────
  // Shown between major actions — e.g. after a case/pack open for free users.
  static const String androidInterstitialAdUnit = 'ca-app-pub-3940256099942544/1033173712'; // TEST
  static const String iosInterstitialAdUnit     = 'ca-app-pub-3940256099942544/4411468910'; // TEST
  // TODO LIVE: replace with your real interstitial unit IDs

  // ── Rewarded ad unit IDs ─────────────────────────────────────────────────
  // Shown when a user wants an extra case/pack open beyond their daily limit.
  static const String androidRewardedAdUnit = 'ca-app-pub-3940256099942544/5224354917'; // TEST
  static const String iosRewardedAdUnit     = 'ca-app-pub-3940256099942544/1712485313'; // TEST
  // TODO LIVE: replace with your real rewarded unit IDs
}
