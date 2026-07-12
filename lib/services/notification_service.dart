import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_notification_service.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static late final GlobalKey<NavigatorState> _navigatorKey;

  static const String _channelId = 'security_alerts';
  static const String _channelName = 'Security Alerts';
  static const String _channelDescription =
      'Notifications for all security updates.';

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    if (Platform.isAndroid) {
      await _setupAndroidNotificationChannel();
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _requestPermission();
    await _configureFirebaseMessagingHandlers();
  }

  static Future<void> _setupAndroidNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _requestPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  static Future<void> _configureFirebaseMessagingHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.notification == null) {
      return;
    }

    await _showLocalNotification(message);
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    _navigateToNotificationsScreen(message.data);
  }

  static Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _navigateToNotificationsScreen(message.data);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification!;
    final android = notification.android;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _navigateToNotificationsScreen(<String, dynamic>{});
      return;
    }

    try {
      final data = Map<String, dynamic>.from({});
      _navigateToNotificationsScreen(data);
    } catch (_) {
      _navigateToNotificationsScreen(<String, dynamic>{});
    }
  }

  static Future<void> subscribeToSecurityTopic() async {
    await _messaging.subscribeToTopic('security_all');
  }

  static Future<void> unsubscribeFromSecurityTopic() async {
    await _messaging.unsubscribeFromTopic('security_all');
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static void _navigateToNotificationsScreen(Map<String, dynamic> data) {
    _navigatorKey.currentState?.pushNamed('/notifications', arguments: data);
  }
}

Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}
