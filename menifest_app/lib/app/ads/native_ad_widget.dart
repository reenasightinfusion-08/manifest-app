import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/common/core.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;
  final double? height;

  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.medium,
    this.height,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdService.supported) return;
    _ad = NativeAd(
      adUnitId: AdIds.native,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: AppColors.white,
        cornerRadius: 18,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.white,
          backgroundColor: AppColors.purple,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textDark,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textGrey,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textGrey,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Native failed: $e');
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    final small = widget.templateType == TemplateType.small;
    final contentHeight = widget.height ?? (small ? 91.0 : 355.0);
    return Container(
      height: contentHeight + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
