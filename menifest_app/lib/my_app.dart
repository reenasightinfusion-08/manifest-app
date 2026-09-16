import 'package:flutter/material.dart';
import 'core/common/core.dart';
import 'app/screens/splash_screen/splash_screen.dart';
import 'app/screens/on_boarding_screen/onboarding_screen.dart';
import 'app/screens/home_screen.dart';
import 'app/screens/on_boarding_screen/welcome_screen.dart';
import 'app/screens/on_boarding_screen/security_screen.dart';
import 'app/screens/user_profile/user_info_screen.dart';
import 'app/screens/user_profile/profile_screen.dart';
import 'app/screens/user_profile/edit_profile_screen.dart';
import 'app/screens/user_profile/action_detail_screen.dart';
import 'app/screens/user_profile/vision_board_screen.dart';
import 'app/screens/user_profile/spiritual_archetype_screen.dart';
import 'app/screens/user_profile/privacy_settings_screen.dart';

import 'package:provider/provider.dart';
import 'app/services/onboarding_provider.dart';
import 'app/services/splash_provider.dart';
import 'app/services/manifest_provider.dart';
import 'app/services/user_provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => ManifestProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852), // iPhone 14 Pro size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Manifest App',
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.onboarding: (_) => const OnboardingScreen(),
              AppRoutes.welcome: (_) => const WelcomeScreen(),
              AppRoutes.security: (_) => const SecurityScreen(),
              AppRoutes.userInfo: (_) => const UserInfoScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              AppRoutes.profile: (_) => const ProfileScreen(),
              AppRoutes.editProfile: (_) => const EditProfileScreen(),
              AppRoutes.visionBoard: (_) => const VisionBoardScreen(),
              AppRoutes.spiritualArchetype: (_) =>
                  const SpiritualArchetypeScreen(),
              AppRoutes.privacySettings: (_) => const PrivacySettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.actionDetail) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => ActionDetailScreen(
                    cardData: args['cardData'],
                    plan: args['plan'],
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
