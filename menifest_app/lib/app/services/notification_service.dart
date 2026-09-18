import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import '../../core/common/app_routes.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Shared with MyApp's MaterialApp(navigatorKey: ...) so a notification
  /// tap can navigate even though this service has no BuildContext of its
  /// own.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// The user's in-app "Push Notifications" preference (Notification
  /// Settings screen). Firebase keeps delivering messages regardless of
  /// this — there's no way to un-request an OS permission — so this is
  /// what actually stops a foreground message from being shown while the
  /// toggle is off. UserProvider keeps this in sync with the persisted
  /// preference on every app start.
  static bool notificationsEnabled = true;

  /// Prompts the OS permission dialog (iOS; the runtime POST_NOTIFICATIONS
  /// prompt on Android 13+, a no-op returning granted below that). Used
  /// when the user flips the in-app toggle on, so turning it on from
  /// Notification Settings actually requests access instead of silently
  /// doing nothing if it was never granted at install time.
  static Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> initialize() async {
    // Request permissions for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Initialize local notifications for foreground messages
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notify');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handlePayload(response.payload);
      },
    );

    // Create Android Notification Channels
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null && notificationsEnabled) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // Handle notification click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _navigateForData(message.data);
    });

    // Handle notification click when app is cold-started from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from a terminated-state notification tap');
      _navigateForData(initialMessage.data);
    }
  }

  static void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _navigateForData(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('Failed to decode notification payload "$payload": $e');
    }
  }

  /// Routes a tapped notification to the right screen based on its `type`
  static void _navigateForData(Map<String, dynamic> data) {
    final route = switch (data['type']) {
      'daily_reminder' || 'welcome' || 'plan_ready' => AppRoutes.home,
      _ => null,
    };
    if (route == null) return;

    void go() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
    }

    if (navigatorKey.currentState != null) {
      go();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/ic_stat_notify',
          color: Color(0xFF7B2FF7), // AppColors.purple
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Fires whenever Firebase issues this device a new token
  static Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  static Future<String?> getToken() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint("FCM Token (attempt $attempt): $token");
          return token;
        }
        debugPrint("FCM getToken() returned null (attempt $attempt)");
      } catch (e) {
        debugPrint("Error getting FCM token (attempt $attempt): $e");
      }
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }
}
