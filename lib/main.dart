import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: HydroTrackApp()));
}

class HydroTrackApp extends StatelessWidget {
  const HydroTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroTrack',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          children: [
            Text('HydroTrack 🌱', style: TextStyle(fontSize: 32)),
            SizedBox(height: 16),
            Text('Michelle Vanegas, Luis Medina, Diego Bravo'), style: TextStyle(fontSize: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}