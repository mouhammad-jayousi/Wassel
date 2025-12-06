import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();  // Temporarily disabled
  
  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      // TODO: Show notification UI when local notifications are re-enabled
    });
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.messageId}');
      // TODO: Navigate to appropriate screen
    });
    
    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Listen to token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }
  
  // Local notifications methods temporarily removed due to compatibility issues
  // Will be re-added when flutter_local_notifications is updated
  
  /// Save FCM token to Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      // Save token to user document
      // You'll need to pass userId when calling this
      print('New FCM token: $token');
    } catch (e) {
      print('Error saving token: $e');
    }
  }
  
  /// Save token for specific user
  Future<void> saveUserToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user token: $e');
    }
  }
  
  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
