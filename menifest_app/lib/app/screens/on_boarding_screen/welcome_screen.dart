import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../widgets/primary_button.dart';
import '../../services/user_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _nameSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  final TextEditingController _passcodeController = TextEditingController();

  @override
  void dispose() {
    _fadeController.dispose();
    _nameSearchController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          'RECOVER IDENTITY',
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            color: AppColors.purple,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your name and cosmic passcode to reconnect.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
            20.verticalSpace,
            TextField(
              controller: _nameSearchController,
              decoration: InputDecoration(
                hintText: 'Your Full Name...',
                filled: true,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                fillColor: AppColors.surfaceVeryLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            12.verticalSpace,
            TextField(
              controller: _passcodeController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: '4-Digit Passcode',
                filled: true,
                counterText: "",
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                fillColor: AppColors.surfaceVeryLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp),
            ),
          ),
          Consumer<UserProvider>(
            builder: (context, provider, _) => ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (_nameSearchController.text.trim().isEmpty) return;
                      if (_passcodeController.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter your 4-digit passcode 🔒',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final success = await provider.joinExistingProfile(
                          _nameSearchController.text.trim(),
                          _passcodeController.text.trim(),
                        );
                        if (!context.mounted) return;
                        if (success) {
                          _nameSearchController.clear();
                          _passcodeController.clear();
                          Navigator.pop(context); // Close dialog
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.home,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Welcome back, Manifestor! ✨'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Identity not found. Try again? 🌌',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: provider.isLoading
                  ? SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('JOIN', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.purple.withValues(alpha: 0.05),
                    AppColors.white,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ...List.generate(3, (i) {
                            return Container(
                              width: (200 + (i * 60.0)).w,
                              height: (200 + (i * 60.0)).w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.purple.withValues(
                                    alpha: 0.04 - (i * 0.01),
                                  ),
                                  width: 1.w,
                                ),
                              ),
                            );
                          }),
                          Container(
                            width: 220.w,
                            height: 220.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: AppColors.softGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 40.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(110.w),
                              child: Image.asset(
                                'assets/images/welcome.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 100.w,
                                      color: AppColors.purple.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  60.verticalSpace,
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'YOUR JOURNEY STARTS NOW',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.purple.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 14.sp,
                          ),
                        ),
                        16.verticalSpace,
                        Text(
                          'Welcome to Your\nReality ✨',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            fontSize: 28.sp,
                          ),
                        ),
                        24.verticalSpace,
                        Text(
                          'Take a deep breath. Your intentions are set, and the universe is ready to listen.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textGrey,
                            height: 1.7,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: 'Begin My Transformation',
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.userInfo,
                          ),
                        ),
                        16.verticalSpace,
                        TextButton(
                          onPressed: _showJoinDialog,
                          child: Text(
                            'ALREADY HAVE A CONNECTION? JOIN BY NAME',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.purple.withValues(alpha: 0.5),
                              fontSize: 10.sp,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  48.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
