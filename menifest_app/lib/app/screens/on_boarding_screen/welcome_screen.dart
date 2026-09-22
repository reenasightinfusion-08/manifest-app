import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/primary_text_field.dart';
import '../../services/user_provider.dart';
import '../../services/api_service.dart' show EmailNotVerifiedException;
import '../security/verify_email_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _emailController = TextEditingController();

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

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
              'Enter your email and password to reconnect.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
            20.verticalSpace,
            PrimaryTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Your Email...',
              prefixIcon: Icons.alternate_email_rounded,
            ),
            12.verticalSpace,
            PrimaryTextField(
              controller: _passwordController,
              obscureText: true,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
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
                      final email = _emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email 📧'),
                          ),
                        );
                        return;
                      }
                      if (_passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password 🔒'),
                          ),
                        );
                        return;
                      }

                      try {
                        final success = await provider.loginWithEmail(
                          email,
                          _passwordController.text,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          _emailController.clear();
                          _passwordController.clear();
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
                                'Invalid email or password. Try again? 🌌',
                              ),
                            ),
                          );
                        }
                      } on EmailNotVerifiedException catch (e) {
                        // Right password, but the emailed link was never
                        // tapped — send them to the same waiting screen
                        // signup uses, instead of a generic error toast.
                        if (!context.mounted) return;
                        _passwordController.clear();
                        Navigator.pop(context); // Close dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerifyEmailScreen(
                              userId: e.userId,
                              email: e.email,
                              finishesSignup: false,
                            ),
                            settings: const RouteSettings(
                              name: AppRoutes.verifyEmail,
                            ),
                          ),
                        );
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
      // The "Recover Identity" dialog opens a keyboard for its own text
      // fields; without this, this screen's Scaffold behind the dialog
      // also resizes for that keyboard and its fixed-height content
      // (image circle, text, button) overflows at the bottom.
      resizeToAvoidBottomInset: false,
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
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.userInfo),
                        ),
                        16.verticalSpace,
                        TextButton(
                          onPressed: _showJoinDialog,
                          child: Text(
                            'ALREADY HAVE AN ACCOUNT? LOG IN',
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
