import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/plant_selector_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/onboarding/perfil_screen.dart';
import 'presentation/screens/onboarding/esp32_vinculacion_screen.dart';
import 'presentation/screens/onboarding/sms_verification_screen.dart';
import 'presentation/screens/onboarding/vinculation_screen.dart';
import 'presentation/screens/onboarding/welcome_screen.dart';

/// Centralized route definitions.
sealed class AppRoutes {
  AppRoutes._();
  static const String dashboard = '/dashboard';
  static const String plantas = '/plantas';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String onboardingPerfil = '/onboarding/perfil';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingEsp32 = '/onboarding/esp32';
  static const String onboardingSms = '/onboarding/sms';
  static const String onboardingVinculacion = '/onboarding/vinculacion';
}

/// Root application widget.
///
/// Responsible for:
/// - MaterialApp theming
/// - Navigation route table
/// - Riverpod ProviderScope
class HydroTrackApp extends StatelessWidget {
  const HydroTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
      routes: {
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.plantas: (context) => const PlantSelectorScreen(),
        AppRoutes.history: (context) => const HistoryScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.onboardingPerfil: (context) => const PerfilScreen(),
        AppRoutes.onboardingWelcome: (context) => const WelcomeScreen(),
        AppRoutes.onboardingEsp32: (context) => const Esp32VinculacionScreen(),
        AppRoutes.onboardingSms: (context) => const SmsVerificationScreen(),
        AppRoutes.onboardingVinculacion: (context) => const VinculacionScreen(),
      },
    );
  }
}
