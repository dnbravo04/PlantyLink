import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // ── Foreground FCM messages → local notification ───────────────────────
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
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

    // ── FCM token (useful for server-side targeting) ───────────────────────
    _fcm.getToken().then((token) => debugPrint('[FCM] token: $token'));
    _onTokenRefreshSub = _fcm.onTokenRefresh.listen(
      (token) => debugPrint('[FCM] token refreshed: $token'),
    );
  }

  /// Cancel active subscriptions. Called if the service is ever torn down.
  void dispose() {
    _onMessageSub?.cancel();
    _onTokenRefreshSub?.cancel();
  }

  /// Shows a local notification for a trend alert detected in-app.
  ///
  /// Uses a stable ID per [sensorKey] so rapid repeat alerts replace each
  /// other instead of stacking.
  Future<void> showTrendAlert(String sensorKey, String message) async {
    final id = sensorKey.hashCode.abs() % 10000;
    await _local.show(
      id,
      '⚠️ Alerta de sensor',
      message,
      NotificationDetails(
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
