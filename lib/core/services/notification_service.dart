import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_constants.dart';

/// Top-level FCM background handler — must be a bare function (not a closure).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs on Android.
  // No-op: the system notification is shown automatically by FCM.
}

/// Centralizes all push-notification concerns:
///
/// - Requests the `POST_NOTIFICATIONS` permission (Android 13+, iOS).
/// - Registers the FCM background handler.
/// - Creates the Android notification channel used for sensor alerts.
/// - Shows a local notification for foreground FCM messages and for
///   in-app trend alerts (when the app is open but the user is on another tab).
/// - Exposes [showTrendAlert] so [TrendNotifier] can fire local notifications
///   without coupling to FCM directly.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<User?>? _onAuthSub;

  static const _channelId = 'plantylink_alerts';
  static const _channelName = 'Alertas PlantyLink';
  static const _channelDesc = 'Alertas de tendencia de sensores hidropónicos';

  /// Call once from [main] before [runApp].
  Future<void> init() async {
    // ── Background handler ────────────────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ── Permissions ───────────────────────────────────────────────────────
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // ── Android notification channel ──────────────────────────────────────
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // ── flutter_local_notifications init ──────────────────────────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // ── Foreground FCM messages → local notification ───────────────────────
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // ── FCM token → RTDB, so Cloud Functions can target this device ────────
    _onAuthSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _syncTokenForUser(user.uid);
    });
    _onTokenRefreshSub = _fcm.onTokenRefresh.listen((token) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _writeToken(uid, token);
    });
  }

  Future<void> _syncTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _writeToken(uid, token);
    } catch (e) {
      debugPrint('[FCM] token sync failed: $e');
    }
  }

  Future<void> _writeToken(String uid, String token) {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).ref('usuarios/$uid/fcm_token').set(token);
  }

  /// Cancel active subscriptions. Called if the service is ever torn down.
  void dispose() {
    _onMessageSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onAuthSub?.cancel();
  }

  /// Shows a local notification for a trend alert detected in-app.
  ///
  /// Uses a stable ID per [sensorKey] so rapid repeat alerts replace each
  /// other instead of stacking.
  Future<void> showTrendAlert(String sensorKey, String message) async {
    final id = sensorKey.hashCode.abs() % 10000;
    await _local.show(
      id: id,
      title: '⚠️ Alerta de sensor',
      body: message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
