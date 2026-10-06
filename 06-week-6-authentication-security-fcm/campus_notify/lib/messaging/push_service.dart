import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

String? pendingDeepLink;

// Callback untuk klik local notification.
// Akan diisi dari main.dart setelah GoRouter dibuat.
void Function(String route)? onLocalNotificationTap;

// ============================================================
// ROUTE PARSER
// ============================================================

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';

  if (route.isEmpty) {
    return '/';
  }

  return route.startsWith('/') ? route : '/$route';
}

// ============================================================
// REQUEST NOTIFICATION PERMISSION
// ============================================================

Future<bool> requestNotificationPermission() async {
  final settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  return settings.authorizationStatus ==
          AuthorizationStatus.authorized ||
      settings.authorizationStatus ==
          AuthorizationStatus.provisional;
}

// ============================================================
// INITIALIZE LOCAL NOTIFICATIONS
// ============================================================

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const ios = DarwinInitializationSettings();

  await _local.initialize(
    settings: const InitializationSettings(
      android: android,
      iOS: ios,
    ),
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;

      if (route == null || route.isEmpty) {
        return;
      }

      if (onLocalNotificationTap != null) {
        onLocalNotificationTap!(route);
      } else {
        pendingDeepLink = route;
      }
    },
  );
}

// ============================================================
// FCM TOKEN + TOPIC
// ============================================================

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await onToken(token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic(
    'pengumuman-kampus',
  );
}

// ============================================================
// FOREGROUND + BACKGROUND CLICK
// ============================================================

void listenForeground(
  void Function(String route) go,
) {
  // ==========================================================
  // FOREGROUND
  // ==========================================================

  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);

    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
      ),
      payload: route,
    );
  });

  // ==========================================================
  // BACKGROUND -> USER KLIK NOTIFIKASI
  // ==========================================================

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = routeFromMessage(message.data);

    go(route);
  });
}

// ============================================================
// TERMINATED
// ============================================================

Future<void> handleTerminated(
  void Function(String route) go,
) async {
  final initial =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initial != null) {
    final route = routeFromMessage(initial.data);

    go(route);
  }

  if (pendingDeepLink != null) {
    go(pendingDeepLink!);

    pendingDeepLink = null;
  }
}

// ============================================================
// BACKGROUND HANDLER
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  debugPrint(
    'Background message received: ${message.messageId}',
  );

  debugPrint(
    'Title: ${message.notification?.title}',
  );

  debugPrint(
    'Body: ${message.notification?.body}',
  );

  debugPrint(
    'Data: ${message.data}',
  );
}

// ============================================================
// REGISTER BACKGROUND HANDLER
// ============================================================

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
}

// ============================================================
// TOPIC: SUBSCRIBE
// ============================================================

Future<void> subscribeToCampusTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic(
    'pengumuman-kampus',
  );
}

// ============================================================
// TOPIC: UNSUBSCRIBE
// ============================================================

Future<void> unsubscribeFromCampusTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic(
    'pengumuman-kampus',
  );
}