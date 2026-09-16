import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/manifest_provider.dart';

class ActionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final Map<String, dynamic> plan;

  const ActionDetailScreen({
    super.key,
    required this.cardData,
    required this.plan,
  });

  @override
  State<ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ManifestProvider>();
    _initTts(provider);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initTts(ManifestProvider provider) {
    _flutterTts.setCompletionHandler(() {
      if (mounted) provider.setPlaying(false);
    });
    _flutterTts.setSpeechRate(provider.speechRate);
    _flutterTts.setPitch(1.0);
  }

  Future<void> _updateSpeed(ManifestProvider provider, double delta) async {
    final newRate = (provider.speechRate + delta).clamp(0.2, 1.0);
    provider.setSpeechRate(newRate);
    provider.setPlaying(false);
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(newRate);
  }

  String _getSpeedLabel(double rate) {
    if (rate <= 0.3) return '0.5x';
    if (rate <= 0.45) return '1x';
    if (rate <= 0.6) return '1.5x';
    if (rate <= 0.75) return '2x';
    return '2.5x';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleAudio(ManifestProvider provider) async {
    if (provider.isPlaying) {
      await _flutterTts.stop();
      provider.setPlaying(false);
    } else {
      provider.setPlaying(true);
      await _flutterTts.speak(
        widget.cardData['summary'] ??
            widget.plan['summary'] ??
            'Summary loading...',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Consumer<ManifestProvider>(
        builder: (context, provider, _) => CustomScrollView(
          slivers: [
            // â”€â”€ Hero Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverAppBar(
              expandedHeight: 260.h,
              backgroundColor: AppColors.purple,
              pinned: true,
              leading: Padding(
                padding: EdgeInsets.all(8.r),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Ambient circles
                      Positioned(
                        top: -40.h,
                        right: -40.w,
                        child: Container(
                          width: 180.r,
                          height: 180.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30.h,
                        left: -30.w,
                        child: Container(
                          width: 130.r,
                          height: 130.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 48.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                'STEP ${widget.cardData['day_number']}',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                            16.verticalSpace,
                            Text(
                              widget.cardData['task_title'],
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.white,
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ Audio Player Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 20.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.28),
                            blurRadius: 24.r,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Pulsing play button
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (_, child) => Transform.scale(
                                  scale: provider.isPlaying
                                      ? _pulseAnimation.value
                                      : 1.0,
                                  child: child,
                                ),
                                child: GestureDetector(
                                  onTap: () => _toggleAudio(provider),
                                  child: Container(
                                    width: 58.r,
                                    height: 58.r,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      provider.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppColors.purple,
                                      size: 32.sp,
                                    ),
                                  ),
                                ),
                              ),
                              16.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.isPlaying
                                          ? 'âœ¦ Now Playing'
                                          : 'Listen to Guidance',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      'Tap to ${provider.isPlaying ? 'stop' : 'hear'} your cosmic essence',
                                      style: TextStyle(
                                        color: AppColors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Current speed chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  _getSpeedLabel(provider.speechRate),
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          16.verticalSpace,
                          // Speed controls bar
                          Row(
                            children: [
                              _SpeedButton(
                                label: 'Slower',
                                onTap: () => _updateSpeed(provider, -0.15),
                              ),
                              const Spacer(),
                              _SpeedButton(
                                label: 'Faster',
                                onTap: () => _updateSpeed(provider, 0.15),
                                alignRight: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    28.verticalSpace,

                    // â”€â”€ Section label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: Text(
                        'THE COSMIC ESSENCE',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.5),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // â”€â”€ Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(22.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: AppColors.pink.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(7.r),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.white,
                                  size: 14.sp,
                                ),
                              ),
                              10.horizontalSpace,
                              Text(
                                'Key Insight',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          16.verticalSpace,
                          Text(
                            widget.cardData['summary'] ??
                                (widget.plan['summary'] ??
                                    'Synthesizing cosmic intent...'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool alignRight;

  const _SpeedButton({
    required this.label,
    required this.onTap,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
