import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/app_config.dart';
import 'core/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase may already be initialized (hot restart, etc.).
  }

  // Start in-memory simulation only in demo mode.
  // In production (kDemoMode = false) no demo data is generated.
  if (kDemoMode) {
    DemoDataService().startSimulation();
  }

  runApp(const ProviderScope(child: PlantyLinkApp()));
}
