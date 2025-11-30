import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool get isConnected => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Skip for Linux desktop builds
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'mooves_training_updates',
        'Training Updates',
        description: 'Reminders and progress updates for your training journey',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  static Future<void> registerFCMTokenAfterLogin() async {
    // No cloud messaging in the training-focused app yet.
    return;
  }

  static Future<void> showTestNotification() async {
    await _showNotification(
      title: 'Mooves test notification',
      body: 'This is how reminders will look. Keep moving!',
    );
  }

  static Future<void> showTrainingReminder({required String message}) async {
    await _showNotification(
      title: 'Time to move',
      body: message,
    );
  }

  static Future<void> showGoalCompletedNotification({required String sessionTitle}) async {
    await _showNotification(
      title: 'Goal reached! 🎉',
      body: 'Great job on "$sessionTitle". Generate your QR reward when ready.',
    );
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'mooves_training_updates',
      'Training Updates',
      channelDescription: 'Reminders and progress notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
} 