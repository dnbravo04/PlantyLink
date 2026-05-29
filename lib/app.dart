import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth_gate.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/onboarding/perfil_screen.dart';
import 'presentation/screens/onboarding/esp32_vinculacion_screen.dart';
import 'presentation/screens/onboarding/sms_verification_screen.dart';
import 'presentation/screens/onboarding/vinculation_screen.dart';
import 'presentation/screens/onboarding/welcome_screen.dart';

/// Centralized route definitions.
sealed class AppRoutes {
  AppRoutes._();
  static const String login               = '/login';
  static const String onboardingPerfil    = '/onboarding/perfil';
  static const String onboardingWelcome   = '/onboarding/welcome';
  static const String onboardingEsp32     = '/onboarding/esp32';
  static const String onboardingOtp       = '/onboarding/otp';
  static const String onboardingVinculacion = '/onboarding/vinculacion';
}

/// Root application widget.
class PlantyLinkApp extends ConsumerWidget {
  const PlantyLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'PlantyLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.onboardingPerfil: (_) => const PerfilScreen(),
        AppRoutes.onboardingWelcome: (_) => const WelcomeScreen(),
        AppRoutes.onboardingEsp32: (_) => const Esp32VinculacionScreen(),
        AppRoutes.onboardingOtp: (_) => const SmsVerificationScreen(),
        AppRoutes.onboardingVinculacion: (_) => const VinculacionScreen(),
      },
    );
  }
}
