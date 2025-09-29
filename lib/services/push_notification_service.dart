import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/other_config.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // FCM token al
  static Future<String?> getToken() async {
    if (!OtherConfig.USE_PUSH_NOTIFICATION) return null;
    
    try {
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('FCM Token alınamadı: $e');
      return null;
    }
  }
  
  // Bildirim izinlerini iste
  static Future<bool> requestPermission() async {
    if (!OtherConfig.USE_PUSH_NOTIFICATION) return false;
    
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('Bildirim izni durumu: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Bildirim izni alınamadı: $e');
      return false;
    }
  }
  
  // Foreground bildirim göster
  static void showForegroundNotification(BuildContext context, RemoteMessage message) {
    if (!OtherConfig.USE_PUSH_NOTIFICATION) return;
    
    // Basit bir SnackBar ile bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.notification?.title ?? 'Bildirim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (message.notification?.body != null)
              Text(message.notification!.body!),
          ],
        ),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // Bildirim tıklama işleyicisi
  static void handleNotificationTap(RemoteMessage message) {
    if (!OtherConfig.USE_PUSH_NOTIFICATION) return;
    
    print('Bildirime tıklandı: ${message.notification?.title}');
    
    // Burada bildirim türüne göre yönlendirme yapılabilir
    String? data = message.data['type'];
    
    switch (data) {
      case 'order':
        // Sipariş sayfasına yönlendir
        print('Sipariş bildirimi');
        break;
      case 'product':
        // Ürün sayfasına yönlendir
        print('Ürün bildirimi');
        break;
      case 'promotion':
        // Kampanya sayfasına yönlendir
        print('Kampanya bildirimi');
        break;
      default:
        // Ana sayfaya yönlendir
        print('Genel bildirim');
    }
  }
}