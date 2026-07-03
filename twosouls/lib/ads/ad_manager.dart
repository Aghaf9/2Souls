import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

// ---------------------------------------------------------------------------
// AdManager
//
// Singleton that handles:
//   - MobileAds.instance.initialize() once on app startup (call from main())
//   - Platform-aware unit ID lookup (Android vs iOS)
//   - Interstitial + Rewarded ad pre-loading so they're ready when needed
//
// AdMob does NOT work on Flutter web — all ad calls are no-ops on web so
// the app still runs in your browser dev server without crashing.
// ---------------------------------------------------------------------------

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  /// Call once from main() before runApp(). No-op on web.
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    // Pre-load the interstitial and rewarded ads right away so they're
    // ready to show immediately when needed.
    _loadInterstitial();
    _loadRewarded();
  }

  // ── Platform helpers ──────────────────────────────────────────────────────

  String get _bannerUnitId => Platform.isIOS ? AdConfig.iosBannerAdUnit : AdConfig.androidBannerAdUnit;
  String get _interstitialUnitId => Platform.isIOS ? AdConfig.iosInterstitialAdUnit : AdConfig.androidInterstitialAdUnit;
  String get _rewardedUnitId => Platform.isIOS ? AdConfig.iosRewardedAdUnit : AdConfig.androidRewardedAdUnit;

  // ── Banner ────────────────────────────────────────────────────────────────

  /// Returns a BannerAd sized to the given adaptive width. Callers
  /// should call .dispose() on the returned ad when their widget disposes.
  Future<BannerAd> createBannerAd({required int adWidth}) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);
    final banner = BannerAd(
      adUnitId: _bannerUnitId,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    await banner.load();
    return banner;
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitial = null;
              _loadInterstitial(); // reload for next time
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Shows a pre-loaded interstitial. No-op on web or if not ready.
  void showInterstitial() {
    if (kIsWeb) return;
    _interstitial?.show();
  }

  bool get isInterstitialReady => !kIsWeb && _interstitial != null;

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _rewarded = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              _rewarded = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Shows a rewarded ad (e.g. "watch an ad for a bonus case open").
  /// [onRewarded] is called with the reward amount if the user completes it.
  void showRewarded({required void Function(num amount) onRewarded}) {
    if (kIsWeb) { onRewarded(1); return; } // grant reward immediately on web for testing
    _rewarded?.show(onUserEarnedReward: (_, reward) => onRewarded(reward.amount));
  }

  bool get isRewardedReady => !kIsWeb && _rewarded != null;
}
