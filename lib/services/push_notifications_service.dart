import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'buildapp_notifications',
        'BUILDAPP сповіщення',
        description: 'Сповіщення по обʼєктах, задачах та строках виконання',
        importance: Importance.high,
      );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _requestPermissions();

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      _messaging.onTokenRefresh.listen((token) async {
        await registerToken(token: token);
      });
    } catch (e) {
      debugPrint('Push init error: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Push permission error: $e');
    }
  }

  static Future<void> registerCurrentDevice() async {
    try {
      await initialize();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await registerToken(token: token);
    } catch (e) {
      debugPrint('Register current push device error: $e');
    }
  }

  static Future<void> registerToken({required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty || token.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/push-token/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': defaultTargetPlatform.name,
        }),
      );
    } catch (e) {
      debugPrint('Push token register error: $e');
    }
  }

  static Future<void> unregisterCurrentDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/push-token/unregister'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      debugPrint('Push token unregister error: $e');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    const androidDetails = AndroidNotificationDetails(
      'buildapp_notifications',
      'BUILDAPP сповіщення',
      channelDescription:
          'Сповіщення по обʼєктах, задачах та строках виконання',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? 'BUILDAPP',
      body ?? 'Нове сповіщення',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }
}
