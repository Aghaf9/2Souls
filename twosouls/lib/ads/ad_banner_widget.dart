import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// AdBannerWidget
//
// Drop-in adaptive banner ad. Safe to use anywhere — on web it shows a
// styled placeholder (since AdMob doesn't support Flutter web) so the
// layout doesn't break during dev.
//
// Usage:
//   const AdBannerWidget()   — put in a Column, bottom of a screen, etc.
//
// The widget self-manages its BannerAd lifecycle (load in initState,
// dispose in dispose) so callers don't need to do anything special.
// ---------------------------------------------------------------------------

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb && !_loaded) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final banner = await AdManager.instance.createBannerAd(adWidth: width);
    if (mounted) {
      setState(() {
        _banner = banner;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _WebPlaceholder();

    if (!_loaded || _banner == null) {
      return SizedBox(height: 50, child: Container(color: AppColors.panelBg));
    }

    return Container(
      color: AppColors.bgDark,
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}

/// Shown on web where AdMob isn't supported — styled to match the app
/// dark theme and labeled clearly so it's obvious this is a placeholder.
class _WebPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        border: Border(top: BorderSide(color: AppColors.panelBorder)),
      ),
      child: Center(
        child: Text(
          'AD PLACEHOLDER — AdMob not available on web',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
