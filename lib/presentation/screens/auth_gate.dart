import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../core/firebase_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'onboarding/perfil_screen.dart';

/// Listens to Firebase auth state and routes accordingly:
/// - Not authenticated → [LoginScreen]
/// - Authenticated + demo mode → [MainShell]
/// - Authenticated + profile complete → [MainShell]
/// - Authenticated + new user (no profile) → [PerfilScreen] (start onboarding)
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        if (kDemoMode) {
          return const MainShell();
        }
        return _OnboardingCheck(uid: snapshot.data!.uid);
      },
    );
  }
}

/// Checks whether the authenticated user has completed their profile.
/// Redirects to [PerfilScreen] if not, or [MainShell] if they have.
class _OnboardingCheck extends StatelessWidget {
  final String uid;
  const _OnboardingCheck({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: kFirebaseDatabaseUrl,
      ).ref('usuarios/$uid/nombre').get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        // Profile exists or network error → go to main shell
        if (snap.hasError || snap.data?.value != null) {
          return const MainShell();
        }
        // New user — profile missing, begin onboarding
        return const PerfilScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: c.primary,
        ),
      ),
    );
  }
}
