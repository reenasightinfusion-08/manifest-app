import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/common/core.dart';
import '../services/manifest_provider.dart';
import '../services/user_provider.dart';
import '../widgets/primary_button.dart';
import '../ads/native_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dreamController = TextEditingController();
  String? _lastHandledGoal;

  static const List<Map<String, String>> _promptCategories = [
    {
      'label': 'Career Growth',
      'icon': 'trending_up',
      'prompt':
          'I want to accelerate my career growth, step into leadership, and lead impactful initiatives with clarity and confidence.',
    },
    {
      'label': 'Financial Freedom',
      'icon': 'account_balance_wallet',
      'prompt':
          'I want to build lasting financial independence, unlock multiple income streams, and cultivate an abundance mindset.',
    },
    {
      'label': 'Clarity & Focus',
      'icon': 'psychology',
      'prompt':
          'I want to cultivate deep mental clarity, master my daily habits, and live with focused intent and inner calmness.',
    },
    {
      'label': 'Deep Connections',
      'icon': 'favorite',
      'prompt':
          'I want to attract and nurture authentic, meaningful relationships grounded in mutual respect, trust, and shared growth.',
    },
    {
      'label': 'Peak Health',
      'icon': 'bolt',
      'prompt':
          'I want to optimize my physical and mental energy through restorative sleep, disciplined movement, and vibrant wellness.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.userId != null) {
        context.read<ManifestProvider>().loadHistory(user.userId!);
      }
    });
  }

  @override
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  void _submitManifestation(ManifestProvider provider) {
    final text = _dreamController.text.trim();
    if (text.isEmpty || provider.isLoading) return;
    FocusScope.of(context).unfocus();
    final user = context.read<UserProvider>();
    provider.generateManifestationPlan(
      user.userId ?? '',
      _dreamController.text,
      personalize: user.personalizationEnabled,
    );
  }

  void _applyPrompt(String prompt) {
    _dreamController.text = prompt;
    _dreamController.selection = TextSelection.fromPosition(
      TextPosition(offset: prompt.length),
    );
    setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManifestProvider>(
      builder: (context, provider, _) {
        if (provider.activeGoal.isNotEmpty &&
            provider.activeGoal != _lastHandledGoal) {
          _lastHandledGoal = provider.activeGoal;

          if (!provider.isFocused) {
            _dreamController.text = provider.activeGoal;
          }
        }

        // Show Toast if duplicate is detected
        if (provider.duplicateDetected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You have already manifested this vision! ✨',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                backgroundColor: AppColors.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            provider.clearDuplicateError();
          });
        }

        final user = context.watch<UserProvider>();
        final displayName = user.name.trim().isNotEmpty
            ? user.name.trim().split(' ').first
            : 'there';

        if (context.isTablet) {
          return _buildTabletLayout(context, provider, user, displayName);
        }

        return _buildPhoneLayout(context, provider, user, displayName);
      },
    );
  }

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    ManifestProvider provider,
    UserProvider user,
    String displayName,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF8FE),
              Color(0xFFF3ECFA),
              Color(0xFFFCF0F5),
              Color(0xFFF4EDFE),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60.0,
              right: -40.0,
              child: Container(
                width: 320.0,
                height: 320.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.10),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40.0,
              left: -30.0,
              child: Container(
                width: 280.0,
                height: 280.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.08),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 820.0 : 720.0,
                ),
                child: Container(
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.08),
                        blurRadius: 32.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              isLandscape ? 36.0 : 28.0,
                              24.0,
                              isLandscape ? 36.0 : 28.0,
                              32.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTabletHeader(context, user, displayName),
                                const SizedBox(height: 24.0),
                                _buildTabletHeroBanner(provider),
                                const SizedBox(height: 24.0),
                                _buildTabletFocusAreas(),
                                const SizedBox(height: 20.0),
                                _buildTabletIntentionCanvas(provider),
                                if (provider.invalidReason != null) ...[
                                  const SizedBox(height: 18.0),
                                  _buildTabletInvalidWarning(provider),
                                ],
                                const SizedBox(height: 28.0),
                                if (provider.actionCards.isNotEmpty) ...[
                                  _buildTabletRoadmapSection(provider),
                                  const SizedBox(height: 24.0),
                                ] else ...[
                                  _buildTabletHowItWorks(),
                                  const SizedBox(height: 24.0),
                                ],
                                const NativeAdWidget(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletHeader(
    BuildContext context,
    UserProvider user,
    String displayName,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'MANIFESTATION PLATFORM',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                '${_getGreeting()}, $displayName',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textDark,
                  fontSize: 26.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16.0),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.22),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4.0),
                ),
              ],
            ),
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                image: DecorationImage(
                  image: NetworkImage(user.profileImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletHeroBanner(ManifestProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 24.0,
            offset: const Offset(0, 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.0,
            top: -20.0,
            child: Container(
              width: 140.0,
              height: 140.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 40.0,
            bottom: -40.0,
            child: Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: const Text(
                        'VISION TO REALITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.0,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    if (provider.streakCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 16.0,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '${provider.streakCount} Day Streak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18.0),
                const Text(
                  'What will you\ncreate today?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28.0,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Define your ambition with precision. The system translates your vision into an actionable daily roadmap.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletFocusAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Focus Areas',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 12.0),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: _promptCategories.map((cat) {
            return InkWell(
              onTap: () => _applyPrompt(cat['prompt']!),
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 9.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: AppColors.borderLight, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(cat['icon']!),
                      size: 16.0,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      cat['label']!,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabletIntentionCanvas(ManifestProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: provider.isFocused
                  ? AppColors.purple
                  : AppColors.borderLight,
              width: provider.isFocused ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: provider.isFocused
                    ? AppColors.purple.withValues(alpha: 0.12)
                    : AppColors.purple.withValues(alpha: 0.04),
                blurRadius: provider.isFocused ? 18.0 : 10.0,
                offset: const Offset(0, 4.0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.purple,
                          size: 20.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'YOUR GOAL',
                          style: TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _dreamController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return GestureDetector(
                          onTap: () {
                            _dreamController.clear();
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.0,
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 18.0),
                child: Focus(
                  onFocusChange: (focus) => provider.setFocused(focus),
                  child: TextField(
                    controller: _dreamController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitManifestation(provider),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontSize: 15.0,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      hintText:
                          'Describe what you want to achieve with specific clarity and intention...',
                      hintStyle: TextStyle(
                        color: AppColors.textLightGrey,
                        fontSize: 14.0,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _dreamController,
          builder: (context, value, child) {
            final currentText = value.text.trim();
            final isUnchanged = currentText == provider.activeGoal;
            final isCardsPresent = provider.actionCards.isNotEmpty;

            if (((isUnchanged && isCardsPresent) || currentText.isEmpty) &&
                !provider.isLoading) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 16.0),
                PrimaryButton(
                  label: provider.isLoading
                      ? 'Generating Action Roadmap... ✨'
                      : 'Build My Action Plan ✨',
                  height: 54.0,
                  fontSize: 16.0,
                  onPressed: () => _submitManifestation(provider),
                  isLoading: provider.isLoading,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabletInvalidWarning(ManifestProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC02).withValues(alpha: 0.15),
            blurRadius: 12.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFE6A800),
                size: 22.0,
              ),
              SizedBox(width: 10.0),
              Text(
                'Refine your goal statement',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7A5800),
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            provider.invalidReason!,
            style: const TextStyle(
              color: Color(0xFF5C4000),
              height: 1.5,
              fontSize: 14.0,
            ),
          ),
          if (provider.invalidTip != null &&
              provider.invalidTip!.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC02).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'Tip: ${provider.invalidTip!}',
                style: const TextStyle(
                  color: Color(0xFF7A5800),
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletRoadmapSection(ManifestProvider provider) {
    final pillars = provider.fullAi?['pillars'];
    final steps = provider.actionCards
        .asMap()
        .entries
        .map(
          (entry) => {
            'day_number': entry.key + 1,
            'task_title': entry.value['task_title'],
            'task_description': entry.value['task_description'],
            'summary': (pillars != null && entry.key < (pillars as List).length)
                ? pillars[entry.key]['summary']
                : 'Structuring milestone plan...',
          },
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.5,
              height: 24.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Your Cosmic Roadmap',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22.0,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Actionable milestones to achieve your vision',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18.0),
        ...steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _ActionCard(
              index: entry.key + 1,
              title: entry.value['task_title'],
              summary: entry.value['summary'],
              steps: steps,
              stepIndex: entry.key,
              plan: provider.currentPlan!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletHowItWorks() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_rounded,
                color: AppColors.purple,
                size: 20.0,
              ),
              SizedBox(width: 8.0),
              Text(
                'HOW IT WORKS',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const _ModernStepItem(
            step: '01',
            title: 'Define with Precision',
            subtitle:
                'Articulate your goal clearly. Specificity drives strategic execution.',
          ),
          const SizedBox(height: 14.0),
          const _ModernStepItem(
            step: '02',
            title: 'AI-Generated Roadmap',
            subtitle:
                'Our system decomposes your goal into sequential, actionable pillars.',
          ),
          const SizedBox(height: 14.0),
          const _ModernStepItem(
            step: '03',
            title: 'Track Daily Milestones',
            subtitle:
                'Execute one focused step at a time until your vision materializes.',
          ),
        ],
      ),
    );
  }

  // ── Phone Layout (Preserved 100% Unchanged) ───────────────────────────────
  Widget _buildPhoneLayout(
    BuildContext context,
    ManifestProvider provider,
    UserProvider user,
    String displayName,
  ) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Refined subtle atmospheric light gradients
          Positioned(
            top: -120.h,
            right: -80.w,
            child: Container(
              width: 360.w,
              height: 360.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.1),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240.h,
            left: -100.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.pink.withValues(alpha: 0.07),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header: Modern, Crisp & Clean ───────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.purple,
                                        ),
                                      ),
                                      8.horizontalSpace,
                                      Text(
                                        'MANIFESTATION PLATFORM',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                          fontSize: 10.5.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  6.verticalSpace,
                                  Text(
                                    '${_getGreeting()}, $displayName',
                                    style: AppTextStyles.headingLarge.copyWith(
                                      color: AppColors.textDark,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            14.horizontalSpace,
                            // Refined Profile Avatar
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(2.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white,
                                    image: DecorationImage(
                                      image: NetworkImage(user.profileImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        20.verticalSpace,

                        // ── Hero Banner: Vibrant, Sleek & Modern ────────────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.28),
                                blurRadius: 24.r,
                                offset: Offset(0, 10.h),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20.w,
                                top: -20.h,
                                child: Container(
                                  width: 140.w,
                                  height: 140.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 40.w,
                                bottom: -40.h,
                                child: Container(
                                  width: 100.w,
                                  height: 100.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(22.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          child: Text(
                                            'VISION TO REALITY',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10.sp,
                                              letterSpacing: 1.4,
                                            ),
                                          ),
                                        ),
                                        if (provider.streakCount > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 5.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .local_fire_department_rounded,
                                                  color: Colors.white,
                                                  size: 14.sp,
                                                ),
                                                4.horizontalSpace,
                                                Text(
                                                  '${provider.streakCount} Day Streak',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    16.verticalSpace,
                                    Text(
                                      'What will you\ncreate today?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 25.sp,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    10.verticalSpace,
                                    Text(
                                      'Define your ambition with precision. The system translates your vision into an actionable daily roadmap.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13.5.sp,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        20.verticalSpace,

                        // ── Guided Focus Chips ─────────────────────────────
                        Text(
                          'Focus Areas',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  10.verticalSpace,
                  SizedBox(
                    height: 38.h,
                    child: ListView.separated(
                      padding: EdgeInsets.only(left: 22.w),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _promptCategories.length,
                      separatorBuilder: (context, index) => 8.horizontalSpace,
                      itemBuilder: (context, index) {
                        final cat = _promptCategories[index];
                        return InkWell(
                          onTap: () => _applyPrompt(cat['prompt']!),
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: AppColors.borderLight,
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(cat['icon']!),
                                  size: 15.sp,
                                  color: AppColors.purple,
                                ),
                                8.horizontalSpace,
                                Text(
                                  cat['label']!,
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  18.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Intention Canvas ───────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22.r),
                            border: Border.all(
                              color: provider.isFocused
                                  ? AppColors.purple
                                  : AppColors.borderLight,
                              width: provider.isFocused ? 1.8.w : 1.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: provider.isFocused
                                    ? AppColors.purple.withValues(alpha: 0.12)
                                    : AppColors.purple.withValues(alpha: 0.04),
                                blurRadius: provider.isFocused ? 18.r : 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  18.w,
                                  14.h,
                                  14.w,
                                  4.h,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note_rounded,
                                          color: AppColors.purple,
                                          size: 18.sp,
                                        ),
                                        8.horizontalSpace,
                                        Text(
                                          'YOUR GOAL',
                                          style: TextStyle(
                                            color: AppColors.purple,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.3,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _dreamController,
                                      builder: (context, value, _) {
                                        if (value.text.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return GestureDetector(
                                          onTap: () {
                                            _dreamController.clear();
                                            setState(() {});
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            child: Text(
                                              'Clear',
                                              style: TextStyle(
                                                color: AppColors.textGrey,
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  18.w,
                                  6.h,
                                  18.w,
                                  16.h,
                                ),
                                child: Focus(
                                  onFocusChange: (focus) =>
                                      provider.setFocused(focus),
                                  child: TextField(
                                    controller: _dreamController,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) =>
                                        _submitManifestation(provider),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                      fontSize: 14.5.sp,
                                    ),
                                    decoration: InputDecoration(
                                      filled: false,
                                      hintText:
                                          'Describe what you want to achieve with specific clarity and intention...',
                                      hintStyle: TextStyle(
                                        color: AppColors.textLightGrey,
                                        fontSize: 13.5.sp,
                                        height: 1.45,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Submit / Generate Action Button ────────────────
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _dreamController,
                          builder: (context, value, child) {
                            final currentText = value.text.trim();
                            final isUnchanged =
                                currentText == provider.activeGoal;
                            final isCardsPresent =
                                provider.actionCards.isNotEmpty;

                            if (((isUnchanged && isCardsPresent) ||
                                    currentText.isEmpty) &&
                                !provider.isLoading) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                16.verticalSpace,
                                PrimaryButton(
                                  label: provider.isLoading
                                      ? 'Generating Action Roadmap... ✨'
                                      : 'Build My Action Plan ✨',
                                  onPressed: () =>
                                      _submitManifestation(provider),
                                  isLoading: provider.isLoading,
                                ),
                              ],
                            );
                          },
                        ),

                        // ── Invalid Input Warning Card ────────────────────
                        if (provider.invalidReason != null) ...[
                          20.verticalSpace,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(18.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0xFFFFCC02),
                                width: 1.5.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFCC02,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: const Color(0xFFE6A800),
                                      size: 20.sp,
                                    ),
                                    10.horizontalSpace,
                                    Text(
                                      'Refine your goal statement',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF7A5800),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                12.verticalSpace,
                                Text(
                                  provider.invalidReason!,
                                  style: TextStyle(
                                    color: const Color(0xFF5C4000),
                                    height: 1.5,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                                if (provider.invalidTip != null &&
                                    provider.invalidTip!.isNotEmpty) ...[
                                  10.verticalSpace,
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFCC02,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      'Tip: ${provider.invalidTip!}',
                                      style: TextStyle(
                                        color: const Color(0xFF7A5800),
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // ── Native ad ──────────────────────────────────────
                        32.verticalSpace,
                        const NativeAdWidget(),

                        // ── Active Cosmic Roadmap Section ──────────────────
                        if (provider.actionCards.isNotEmpty) ...[
                          32.verticalSpace,

                          // Section Title
                          Row(
                            children: [
                              Container(
                                width: 4.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: AppColors.primaryGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              12.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Cosmic Roadmap',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20.sp,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      'Actionable milestones to achieve your vision',
                                      style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          16.verticalSpace,

                          Builder(
                            builder: (context) {
                              final pillars = provider.fullAi?['pillars'];
                              final steps = provider.actionCards
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => {
                                      'day_number': entry.key + 1,
                                      'task_title': entry.value['task_title'],
                                      'task_description':
                                          entry.value['task_description'],
                                      'summary':
                                          (pillars != null &&
                                              entry.key <
                                                  (pillars as List).length)
                                          ? pillars[entry.key]['summary']
                                          : 'Structuring milestone plan...',
                                    },
                                  )
                                  .toList();

                              return Column(
                                children: steps
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.only(bottom: 14.h),
                                        child: _ActionCard(
                                          index: entry.key + 1,
                                          title: entry.value['task_title'],
                                          summary: entry.value['summary'],
                                          steps: steps,
                                          stepIndex: entry.key,
                                          plan: provider.currentPlan!,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ] else ...[
                          // ── Modern Insight Banner ─────────────────────────
                          24.verticalSpace,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                color: AppColors.borderLight,
                                width: 1.w,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_rounded,
                                      color: AppColors.purple,
                                      size: 18.sp,
                                    ),
                                    8.horizontalSpace,
                                    Text(
                                      'HOW IT WORKS',
                                      style: TextStyle(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.3,
                                        fontSize: 10.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                14.verticalSpace,
                                const _ModernStepItem(
                                  step: '01',
                                  title: 'Define with Precision',
                                  subtitle:
                                      'Articulate your goal clearly. Specificity drives strategic execution.',
                                ),
                                12.verticalSpace,
                                const _ModernStepItem(
                                  step: '02',
                                  title: 'AI-Generated Roadmap',
                                  subtitle:
                                      'Our system decomposes your goal into sequential, actionable pillars.',
                                ),
                                12.verticalSpace,
                                const _ModernStepItem(
                                  step: '03',
                                  title: 'Track Daily Milestones',
                                  subtitle:
                                      'Execute one focused step at a time until your vision materializes.',
                                ),
                              ],
                            ),
                          ),
                        ],

                        32.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernStepItem extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _ModernStepItem({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isTablet ? 32.0 : 28.r,
          height: isTablet ? 32.0 : 28.r,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isTablet ? 9.0 : 8.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: AppColors.purple,
              fontSize: isTablet ? 12.0 : 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        isTablet ? const SizedBox(width: 12.0) : 12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 14.5 : 13.5.sp,
                  color: AppColors.textDark,
                ),
              ),
              isTablet ? const SizedBox(height: 3.0) : 2.verticalSpace,
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: isTablet ? 13.0 : 12.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final int index;
  final String title;
  final String? summary;
  final Map<String, dynamic> plan;
  final List<Map<String, dynamic>> steps;
  final int stepIndex;

  const _ActionCard({
    required this.index,
    required this.title,
    this.summary,
    required this.plan,
    required this.steps,
    required this.stepIndex,
  });

  void _showDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.actionDetail,
      arguments: {'steps': steps, 'initialIndex': stepIndex, 'plan': plan},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18.0 : 16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
          border: Border.all(
            color: AppColors.borderLight,
            width: isTablet ? 1.0 : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.04),
              blurRadius: isTablet ? 12.0 : 12.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Modern Step Number Indicator
            Container(
              width: isTablet ? 46.0 : 44.w,
              height: isTablet ? 46.0 : 44.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: isTablet ? 8.0 : 8.r,
                    offset: Offset(0, isTablet ? 3.0 : 3.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 16.5 : 16.sp,
                  ),
                ),
              ),
            ),
            isTablet ? const SizedBox(width: 14.0) : 14.horizontalSpace,
            // Title & Preview Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILLAR $index',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: isTablet ? 11.0 : 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  isTablet ? const SizedBox(height: 4.0) : 4.verticalSpace,
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontSize: isTablet ? 14.5 : 14.sp,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary != null && summary!.isNotEmpty) ...[
                    isTablet ? const SizedBox(height: 4.0) : 4.verticalSpace,
                    Text(
                      summary!,
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: isTablet ? 12.0 : 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            isTablet ? const SizedBox(width: 8.0) : 8.horizontalSpace,
            // Directional Arrow
            Container(
              width: isTablet ? 34.0 : 32.r,
              height: isTablet ? 34.0 : 32.r,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.purple,
                size: isTablet ? 13.0 : 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
