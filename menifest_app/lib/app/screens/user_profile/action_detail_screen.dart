import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/manifest_provider.dart';

class ActionDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> steps;
  final int initialIndex;
  final Map<String, dynamic> plan;

  const ActionDetailScreen({
    super.key,
    required this.steps,
    required this.initialIndex,
    required this.plan,
  });

  @override
  State<ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _transitionController;
  bool _isTransitioning = false;
  bool _showAppBarTitle = false;
  late int _currentIndex;

  Map<String, dynamic> get _cardData => widget.steps[_currentIndex];
  bool get _hasPrevious => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.steps.length - 1);
    final provider = context.read<ManifestProvider>();
    _initTts(provider);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    // Play the same fanfare on first opening this screen too, not just on
    // "Next Step" — so stepping into the roadmap feels like a little launch
    // moment from the very first step.
    WidgetsBinding.instance.addPostFrameCallback((_) => _playFanfare());
    _scrollController.addListener(_handleScrollForAppBarTitle);
    _markCurrentStepRead();
  }

  void _markCurrentStepRead() {
    context.read<ManifestProvider>().markStepRead(
      widget.plan['manifestation_id']?.toString(),
      _currentIndex,
      widget.steps.length,
    );
  }

  // Only reveals the app bar title once the big hero title has fully
  // scrolled out of view (i.e. the SliverAppBar is fully collapsed) —
  // otherwise the two titles are visible together during the collapse.
  void _handleScrollForAppBarTitle() {
    final collapseDistance = 260.h - kToolbarHeight;
    final shouldShow = _scrollController.offset >= collapseDistance;
    if (shouldShow != _showAppBarTitle) {
      setState(() => _showAppBarTitle = shouldShow);
    }
  }

  // Plays the fanfare overlay by itself, without changing the step.
  Future<void> _playFanfare() async {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _isTransitioning = true);
    await _transitionController.forward(from: 0);
    if (!mounted) return;
    setState(() => _isTransitioning = false);
    _transitionController.reset();
  }

  // Plays the fanfare, then swaps to the next step — a little delight
  // moment so moving forward feels light, not just an instant content swap.
  Future<void> _goToNextWithFanfare(int newIndex) async {
    if (newIndex < 0 || newIndex >= widget.steps.length) return;
    await _playFanfare();
    await _goToStep(newIndex);
  }

  // Moves to the next/previous step in place — no popping back out to the
  // roadmap list and tapping the next card. Stops any playing audio first
  // since it belongs to whichever step we're leaving, and resets the scroll
  // to the top so the new step always opens from its header, not wherever
  // the previous step happened to be scrolled to.
  Future<void> _goToStep(int newIndex) async {
    if (newIndex < 0 || newIndex >= widget.steps.length) return;
    final provider = context.read<ManifestProvider>();
    if (provider.isPlaying) {
      await _flutterTts.stop();
      provider.setPlaying(false);
    }
    if (!mounted) return;
    setState(() => _currentIndex = newIndex);
    _markCurrentStepRead();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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
    _transitionController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleAudio(ManifestProvider provider) async {
    if (provider.isPlaying) {
      await _flutterTts.stop();
      provider.setPlaying(false);
    } else {
      provider.setPlaying(true);
      final textToRead = (_cardData['task_description'] as String?)?.trim();
      await _flutterTts.speak(
        (textToRead != null && textToRead.isNotEmpty)
            ? textToRead
            : (_cardData['summary'] ??
                  widget.plan['summary'] ??
                  'Content loading...'),
      );
    }
  }

  // Breaks raw guidance text into paragraph-sized chunks. AI output doesn't
  // reliably include blank-line breaks, so when there's only one block we
  // fall back to grouping sentences — otherwise everything renders as one
  // dense slab no matter how the container around it looks.
  List<String> _splitIntoParagraphs(String text) {
    final byBlankLine = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (byBlankLine.length > 1) return byBlankLine;

    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9"‘“])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.length <= 2) return [text.trim()];

    const perParagraph = 2;
    final chunks = <String>[];
    for (var i = 0; i < sentences.length; i += perParagraph) {
      chunks.add(sentences.skip(i).take(perParagraph).join(' '));
    }
    return chunks;
  }

  // One visually distinct card per section of the guidance — a different
  // shape from the single flat container this replaces. Each section gets
  // its own label, icon and accent color so the content reads as several
  // clearly separated pieces instead of one wall of text.
  List<Widget> _buildGuidanceSections(String? text) {
    if (text == null || text.trim().isEmpty) {
      return [
        _GuidanceCard(
          label: 'GUIDANCE',
          icon: Icons.hourglass_empty_rounded,
          color: AppColors.textGrey,
          text:
              'Guidance for this step is still on its way — try refreshing the plan.',
        ),
      ];
    }

    final paragraphs = _splitIntoParagraphs(text.trim());

    const sectionMeta = [
      ('THE BIG PICTURE', Icons.visibility_rounded, AppColors.purple),
      ('WHY IT MATTERS', Icons.psychology_alt_rounded, AppColors.pink),
      ('HOW TO DO IT', Icons.checklist_rounded, AppColors.blue),
      ('KEEP IN MIND', Icons.tips_and_updates_rounded, AppColors.purpleLight),
    ];

    final cards = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      final isLast = i == paragraphs.length - 1;
      if (isLast && paragraphs.length > 1) {
        // Final section is always the standout action card.
        cards.add(_TakeawayCard(text: paragraphs[i]));
      } else {
        final meta = sectionMeta[i % sectionMeta.length];
        cards.add(
          _GuidanceCard(
            label: meta.$1,
            icon: meta.$2,
            color: meta.$3,
            text: paragraphs[i],
          ),
        );
      }
      if (!isLast) cards.add(14.verticalSpace);
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Consumer<ManifestProvider>(
        builder: (context, provider, _) => Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Hero Header ──────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 260.h,
                  backgroundColor: AppColors.purple,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  shadowColor: AppColors.transparent,
                  surfaceTintColor: AppColors.transparent,
                  centerTitle: true,
                  // Only fades in once the hero title below has fully scrolled
                  // out of view (see _handleScrollForAppBarTitle) — so the two
                  // titles are never on screen together.
                  title: AnimatedOpacity(
                    opacity: _showAppBarTitle ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _cardData['task_title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  leadingWidth: 56.w,
                  leading: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.35),
                            width: 1.w,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
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
                                    color: AppColors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: AppColors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'STEP ${_cardData['day_number']}',
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
                                  _cardData['task_title'],
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
                    padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 32.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Audio Player Card ────────────────────────────────────────
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.isPlaying
                                              ? '✨ Now Playing'
                                              : 'Listen to Guidance',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        4.verticalSpace,
                                        Text(
                                          'Tap to ${provider.isPlaying ? 'stop' : 'hear'} this step read aloud',
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
                                      color: AppColors.white.withValues(
                                        alpha: 0.2,
                                      ),
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

                        // ── Quick summary strip — the short, at-a-glance take,
                        // kept small on purpose so it doesn't compete with the
                        // full guidance below.
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: AppColors.purple,
                                size: 18.sp,
                              ),
                              10.horizontalSpace,
                              Expanded(
                                child: Text(
                                  _cardData['summary'] ??
                                      (widget.plan['summary'] ?? ''),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        28.verticalSpace,

                        // ── Section label ────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Text(
                            'YOUR FULL GUIDANCE',
                            style: TextStyle(
                              color: AppColors.purple.withValues(alpha: 0.6),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        12.verticalSpace,

                        // ── Full guidance — several distinct cards (one per
                        // section, each its own color/icon/label), ending in a
                        // bold takeaway card. Replaces the single flat white
                        // box that used to hold everything.
                        ..._buildGuidanceSections(
                          _cardData['task_description'] as String?,
                        ),

                        28.verticalSpace,

                        // ── Step navigation — move straight to the next/
                        // previous step without popping back to the roadmap.
                        // On the final step, "Next Step" becomes "Done", which
                        // exits back to whichever screen opened this roadmap.
                        Row(
                          children: [
                            if (_hasPrevious)
                              Expanded(
                                child: _StepNavButton(
                                  label: 'Previous',
                                  icon: Icons.arrow_back_rounded,
                                  filled: false,
                                  iconLeading: true,
                                  onTap: () => _goToStep(_currentIndex - 1),
                                ),
                              ),
                            if (_hasPrevious) 12.horizontalSpace,
                            Expanded(
                              child: _hasNext
                                  ? _StepNavButton(
                                      label: 'Next Step',
                                      icon: Icons.arrow_forward_rounded,
                                      filled: true,
                                      iconLeading: false,
                                      onTap: () => _goToNextWithFanfare(
                                        _currentIndex + 1,
                                      ),
                                    )
                                  : _StepNavButton(
                                      label: 'Done',
                                      icon: Icons.check_rounded,
                                      filled: true,
                                      iconLeading: false,
                                      onTap: () => Navigator.pop(context),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isTransitioning)
              Positioned.fill(
                child: _StepFanfareOverlay(animation: _transitionController),
              ),
          ],
        ),
      ),
    );
  }
}

// A short, playful "onward!" overlay shown for a beat while advancing to
// the next step — a rocket that pops in with a bounce, a couple of trailing
// sparkles, and a fun label, so moving forward feels like a little reward
// instead of an instant content swap.
class _StepFanfareOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _StepFanfareOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value.clamp(0.0, 1.0);
          // Fade in fast, hold, fade out over the last quarter.
          final fadeIn = (t / 0.2).clamp(0.0, 1.0);
          final fadeOut = t > 0.75
              ? (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0)
              : 1.0;
          final opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);
          final bounce = Curves.elasticOut.transform((t / 0.7).clamp(0.0, 1.0));
          final rise = (1 - bounce) * 30;

          // The backdrop itself always stays fully opaque for the whole
          // animation — only the icon/text inside fade in and out. Fading
          // the backdrop too (as before) let the step content behind bleed
          // through during the transition, which looked broken.
          return Container(
            color: const Color(0xFFF8F5FF),
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      _sparkle(-46, -18, t, 0.05),
                      _sparkle(44, -26, t, 0.15),
                      _sparkle(-34, 30, t, 0.25),
                      _sparkle(40, 26, t, 0.1),
                      Transform.translate(
                        offset: Offset(0, rise),
                        child: Transform.scale(
                          scale: 0.4 + bounce * 0.8,
                          child: Text('🚀', style: TextStyle(fontSize: 64.sp)),
                        ),
                      ),
                    ],
                  ),
                  20.verticalSpace,
                  Text(
                    'Onward! ✨',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sparkle(double dx, double dy, double t, double delay) {
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    final pop = Curves.easeOut.transform(local);
    return Transform.translate(
      offset: Offset(dx * pop, dy * pop),
      child: Opacity(
        opacity: (1 - local).clamp(0.0, 1.0),
        child: Text(
          '✦',
          style: TextStyle(fontSize: 16.sp, color: AppColors.purple),
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

class _StepNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool iconLeading;
  final VoidCallback onTap;

  const _StepNavButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.iconLeading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 18.sp,
      color: filled ? AppColors.white : AppColors.purple,
    );
    final textWidget = Text(
      label,
      style: TextStyle(
        color: filled ? AppColors.white : AppColors.purple,
        fontSize: 14.sp,
        fontWeight: FontWeight.w800,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: filled ? null : AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconLeading
              ? [iconWidget, 8.horizontalSpace, textWidget]
              : [textWidget, 8.horizontalSpace, iconWidget],
        ),
      ),
    );
  }
}

// One section of the guidance content: a soft-tinted card with a colored
// icon chip, an eyebrow label, and the paragraph text. Distinct shape/color
// per section is what makes the content read as several pieces, not one box.
class _GuidanceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String text;

  const _GuidanceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 14.sp),
              ),
              8.horizontalSpace,
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDark,
              height: 1.65,
              fontSize: 15.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// The standout final card — the one clear action for this step, in a bold
// gradient block so it visually anchors the whole section.
class _TakeawayCard extends StatelessWidget {
  final String text;

  const _TakeawayCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.white, size: 16.sp),
              8.horizontalSpace,
              Text(
                'TAKE THIS ACTION',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              height: 1.6,
              fontSize: 15.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}
