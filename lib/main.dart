import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase may already be initialized.
  }

  // Initialize demo data and start simulation.
  final demoService = DemoDataService();
  await demoService.initializeDemoData();
  demoService.startSimulation();
  demoService.listenToControls();

  runApp(const ProviderScope(child: HydroTrackApp()));
}
