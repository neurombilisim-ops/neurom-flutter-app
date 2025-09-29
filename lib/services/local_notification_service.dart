import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Bildirim servisini başlat
  static Future<void> initialize() async {
    if (_initialized) return;

    // Android ayarları
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('✅ Local Notification Service başlatıldı');
  }

  // Bildirim tıklama işleyicisi
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Bildirime tıklandı: ${response.payload}');
    // Burada bildirim türüne göre yönlendirme yapılabilir
  }

  // Firebase mesajını sistem bildirimi olarak göster
  static Future<void> showNotification(RemoteMessage message) async {
    if (!_initialized) {
      await initialize();
    }

    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'neurom_channel',
      'Neurom Bildirimleri',
      channelDescription: 'Neurom uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode, // Benzersiz ID
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );

    print('📱 Sistem bildirimi gösterildi: ${notification.title}');
  }

  // Test bildirimi göster
  static Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'neurom_channel',
      'Neurom Bildirimleri',
      channelDescription: 'Neurom uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Test ID
      'Test Bildirimi',
      'Neurom bildirim sistemi çalışıyor!',
      details,
      payload: 'test',
    );

    print('🧪 Test bildirimi gösterildi');
  }

  // Bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Belirli bir bildirimi iptal et
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}

