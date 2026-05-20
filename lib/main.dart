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
  } catch (_) {
    // Firebase may already be initialized (hot restart, etc.).
  }

  // Start the in-memory simulation.
  // initializeDemoData() and listenToControls() have been removed:
  // DemoDataService no longer writes to or reads from Firebase.
  DemoDataService().startSimulation();

  runApp(const ProviderScope(child: HydroTrackApp()));
}