import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'url_strategy_noop.dart'
    if (dart.library.js_util) 'url_strategy_web.dart';
import 'my_app.dart';
import 'app/services/notification_service.dart';
import 'app/services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize Notification Service
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // Continue even if firebase fails (e.g. missing google-services.json)
  }

  // Restore any server address saved from the in-app connection settings
  // (Privacy Settings) so a release build survives the PC's LAN IP changing.
  await ApiService.loadSavedBaseUrl();

  usePathUrlStrategy();
  runApp(const MyApp());
}
