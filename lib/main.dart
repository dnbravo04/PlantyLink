import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/plant_selector_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding/sms_verification_screen.dart';
import 'screens/onboarding/perfil_screen.dart';
import 'screens/onboarding/esp32_vinculacion_screen.dart';
import 'screens/onboarding/vinculation_screen.dart';
import 'core/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ya inicializado
  }

  // Inicializar datos demo (fuera del try para que siempre se ejecute)
  final demoService = DemoDataService();
  await demoService.initializeDemoData();
  demoService.startSimulation();
  demoService.listenToControls();

  runApp(const ProviderScope(child: HydroTrackApp()));
}

class HydroTrackApp extends StatelessWidget {
  const HydroTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const DashboardScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/plantas': (context) => const PlantSelectorScreen(),
        '/history': (context) => const HistoryScreen(),
        '/onboarding/perfil': (context) => const PerfilScreen(),
        '/onboarding/esp32': (context) => const Esp32VinculacionScreen(),
        '/onboarding/sms': (context) => const SmsVerificationScreen(),
        '/onboarding/vinculacion': (context) => const VinculacionScreen(),
      },
    );
  }
}
