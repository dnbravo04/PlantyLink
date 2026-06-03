import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/app_config.dart';
import 'core/demo_data_service.dart';
import 'core/firebase_constants.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable disk persistence so the app works offline and syncs on reconnect.
    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).setPersistenceEnabled(true);
  } catch (_) {
    // Firebase may already be initialized (hot restart, etc.).
  }

  // Initialize push notifications (requests permission, registers FCM handlers,
  // creates Android notification channel). Skipped in demo mode and on web.
  if (!kDemoMode && !kIsWeb) {
    await NotificationService.instance.init();
  }

  // Start in-memory simulation only in demo mode.
  if (kDemoMode) {
    DemoDataService().startSimulation();
  }

  runApp(const ProviderScope(child: PlantyLinkApp()));
}
