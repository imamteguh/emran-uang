import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

/// Top-level background message handler.
/// Must be top-level or static, otherwise it throws.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed (often necessary for background message handling)
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _singleton = PushNotificationService._internal();
  final DioClient _dioClient = DioClient();
  bool _initialized = false;

  factory PushNotificationService() {
    return _singleton;
  }

  PushNotificationService._internal();

  /// Initialize Firebase & FCM
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase (safely wraps for web or platforms without setup)
      await Firebase.initializeApp();
      
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User granted notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Retrieve FCM token
        // Use default web push keys (VAPID) if on web, but let's try standard getToken first
        String? token;
        try {
          token = await messaging.getToken();
        } catch (tokenError) {
          debugPrint('Error getting FCM token: $tokenError');
        }

        if (token != null) {
          debugPrint('FCM Token: $token');
          await registerToken(token);
        }

        // Listen to token refreshes
        messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM Token Refreshed: $newToken');
          await registerToken(newToken);
        });

        // Listen to foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Received foreground notification: ${message.notification?.title}');
          // If you need to trigger in-app updates, you can notify users or providers here
        });

        // Listen to notification clicks when app is in background but still running
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification clicked: ${message.notification?.title}');
        });

        // Check if app was opened from a terminated state via a notification
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('App opened from terminated state via notification: ${initialMessage.notification?.title}');
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Push Notification Service failed to initialize gracefully: $e');
      debugPrint('[FCM] Running in fallback mode without push notifications.');
    }
  }

  /// Register the token on our Backend
  Future<void> registerToken(String token) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/fcm-token',
        data: {'fcmToken': token},
      );
      if (response.statusCode == 200) {
        debugPrint('[FCM] Registered token on server.');
      } else {
        debugPrint('[FCM] Failed to register token: ${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token on server: $e');
    }
  }

  /// Clear the token on our Backend (e.g. on logout)
  Future<void> clearToken() async {
    try {
      await _dioClient.dio.post(
        '/auth/fcm-token',
        data: {'fcmToken': null},
      );
      debugPrint('[FCM] Cleared token from server.');
    } catch (e) {
      debugPrint('[FCM] Error clearing token from server: $e');
    }
  }
}
