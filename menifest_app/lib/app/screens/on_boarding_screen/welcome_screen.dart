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
  final TextEditingController _passwordController = TextEditingController();

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

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showJoinDialog() {
    final isTablet = context.isTablet;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double dialogWidth = isTablet
        ? (isLandscape ? 620.0 : 520.0)
        : double.infinity;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: isTablet ? dialogWidth : null,
          child: AlertDialog(
            backgroundColor: AppColors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32.0 : 20.w,
              vertical: 24.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 24.0 : 24.r),
            ),
            titlePadding: EdgeInsets.fromLTRB(
              isTablet ? 36.0 : 24.w,
              isTablet ? 32.0 : 24.h,
              isTablet ? 36.0 : 24.w,
              0,
            ),
            contentPadding: EdgeInsets.fromLTRB(
              isTablet ? 36.0 : 24.w,
              isTablet ? 20.0 : 16.h,
              isTablet ? 36.0 : 24.w,
              0,
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              isTablet ? 36.0 : 24.w,
              isTablet ? 20.0 : 16.h,
              isTablet ? 36.0 : 24.w,
              isTablet ? 28.0 : 20.h,
            ),
            title: Text(
              'RECOVER IDENTITY',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: AppColors.purple,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: isTablet ? 14.5 : 12.sp,
              ),
            ),
            content: SizedBox(
              width: isTablet ? dialogWidth : null,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter your email and password to reconnect.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGrey,
                        fontSize: isTablet ? 13.5 : 12.sp,
                      ),
                    ),
                    SizedBox(height: isTablet ? 24.0 : 20.h),
                    PrimaryTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Your Email...',
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    SizedBox(height: isTablet ? 16.0 : 12.h),
                    PrimaryTextField(
                      controller: _passwordController,
                      obscureText: true,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20.0 : 12.w,
                    vertical: isTablet ? 12.0 : 8.h,
                  ),
                ),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: isTablet ? 13.0 : 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 28.0 : 16.w,
                      vertical: isTablet ? 14.0 : 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isTablet ? 12.0 : 12.r,
                      ),
                    ),
                  ),
                  child: provider.isLoading
                      ? SizedBox(
                          width: isTablet ? 16.0 : 15.w,
                          height: isTablet ? 16.0 : 15.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'JOIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 13.5 : 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final isLandscape = context.isLandscape;

    if (!isTablet) {
      return Scaffold(
        backgroundColor: AppColors.white,
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
                    32.verticalSpace,
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
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.userInfo,
                            ),
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
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tablet Layout (Portrait and Landscape)
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            SafeArea(
              child: isLandscape
                  ? _buildTabletLandscape(context)
                  : _buildTabletPortrait(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLandscape(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040.0),
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
                offset: const Offset(0, 8.0),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10.0,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 32.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Concentric illustration circle (50% equal width)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: _buildTabletCircleImage(imageSize: 280.0),
                    ),
                  ),
                ),
                const SizedBox(width: 32.0),
                // Right: Content and Actions (50% equal width, vertically & horizontally centered)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420.0),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'YOUR JOURNEY STARTS NOW',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.purple.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  fontSize: 13.0,
                                ),
                              ),
                              const SizedBox(height: 14.0),
                              Text(
                                'Welcome to Your Reality ✨',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                  height: 1.18,
                                  fontSize: 30.0,
                                ),
                              ),
                              const SizedBox(height: 14.0),
                              Text(
                                'Take a deep breath. Your intentions are set, and the universe is ready to listen.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textGrey,
                                  height: 1.55,
                                  fontSize: 15.0,
                                ),
                              ),
                              const SizedBox(height: 28.0),
                              PrimaryButton(
                                label: 'Begin My Transformation',
                                height: 54.0,
                                fontSize: 15.5,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.userInfo,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              TextButton(
                                onPressed: _showJoinDialog,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'ALREADY HAVE AN ACCOUNT? LOG IN',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.purple.withValues(alpha: 0.6),
                                    fontSize: 11.5,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletPortrait(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860.0),
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
                offset: const Offset(0, 8.0),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10.0,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 36.0,
              vertical: 36.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTabletCircleImage(imageSize: 260.0),
                ),
                const SizedBox(height: 36.0),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'YOUR JOURNEY STARTS NOW',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.purple.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'Welcome to Your\nReality ✨',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          fontSize: 32.0,
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      Text(
                        'Take a deep breath. Your intentions are set, and the universe is ready to listen.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGrey,
                          height: 1.6,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36.0),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Begin My Transformation',
                        height: 56.0,
                        fontSize: 16.0,
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.userInfo),
                      ),
                      const SizedBox(height: 14.0),
                      TextButton(
                        onPressed: _showJoinDialog,
                        child: Text(
                          'ALREADY HAVE AN ACCOUNT? LOG IN',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.purple.withValues(alpha: 0.6),
                            fontSize: 11.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  Widget _buildTabletCircleImage({required double imageSize}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(3, (i) {
          final ringSize = imageSize + ((i + 1) * 36.0);
          return Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.04 - (i * 0.01)),
                width: 1.0,
              ),
            ),
          );
        }),
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: AppColors.softGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.1),
                blurRadius: 40.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageSize / 2),
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.auto_awesome_rounded,
                size: imageSize * 0.45,
                color: AppColors.purple.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
