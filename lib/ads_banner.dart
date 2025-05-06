import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_colors.dart';

class AdsBanner extends StatefulWidget {
  const AdsBanner({super.key});

  @override
  State<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<AdsBanner> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      _bannerAd = BannerAd(
        adUnitId:
            'ca-app-pub-xxxxxxxx/zzzzzzzzzz', // substitua pelo seu ID real
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isAdLoaded = true),
          onAdFailedToLoad: (ad, _) {
            setState(() => error = true);
            ad.dispose();
          },
        ),
      );
      await _bannerAd.load();
      setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 6.0,
            backgroundColor: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (error || !_isAdLoaded) return const SizedBox();

    return Container(
      alignment: Alignment.center,
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
