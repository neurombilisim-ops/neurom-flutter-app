import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:neurom_bilisim_store/screens/notifications.dart';
import 'package:neurom_bilisim_store/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];

  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => _notifications;

  // Bildirim ekle
  void addNotification(RemoteMessage message) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: message.notification?.title ?? 'Bildirim',
      message: message.notification?.body ?? '',
      time: DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'general',
    );

    _notifications.insert(0, notification); // En üste ekle
    _unreadCount++;
    notifyListeners();
  }

  // Bildirimi okundu olarak işaretle
  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount--;
      notifyListeners();
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();
  }

  // Bildirim sayısını güncelle
  void updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  // API'den tüm bildirimleri yükle
  Future<void> loadNotificationsFromAPI() async {
    try {
      final repository = NotificationRepository();
      final response = await repository.getAllNotifications();
      
      if (response['data'] != null) {
        _notifications.clear();
        for (var notificationData in response['data']) {
          final notification = NotificationItem(
            id: int.parse(notificationData['id'].toString()),
            title: notificationData['data']['title'] ?? 'Bildirim',
            message: notificationData['data']['message'] ?? '',
            time: DateTime.parse(notificationData['created_at']),
            isRead: notificationData['read_at'] != null,
            type: notificationData['type'] ?? 'general',
          );
          _notifications.add(notification);
        }
        updateUnreadCount();
      }
    } catch (e) {
      print('Bildirimler yüklenirken hata: $e');
    }
  }

  // API'den okunmamış bildirim sayısını yükle
  Future<void> loadUnreadCountFromAPI() async {
    try {
      print('🔔 Okunmamış bildirim sayısı yükleniyor...');
      final repository = NotificationRepository();
      final response = await repository.getUnreadNotifications();
      
      print('🔔 API Response: $response');
      
      if (response['count'] != null) {
        _unreadCount = response['count'];
        print('🔔 Okunmamış bildirim sayısı: $_unreadCount');
        notifyListeners();
      } else {
        print('🔔 Count null, response: $response');
      }
    } catch (e) {
      print('❌ Okunmamış bildirim sayısı yüklenirken hata: $e');
    }
  }

  // API ile bildirimi okundu olarak işaretle
  Future<void> markAsReadAPI(String notificationId) async {
    try {
      final repository = NotificationRepository();
      await repository.markNotificationAsRead(notificationId);
      
      // Local state'i de güncelle
      markAsRead(int.parse(notificationId));
    } catch (e) {
      print('Bildirim okundu işaretlenirken hata: $e');
    }
  }

  // API ile tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsReadAPI() async {
    try {
      // Tüm okunmamış bildirimleri API'ye gönder
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id.toString())
          .toList();
      
      if (unreadIds.isNotEmpty) {
        final repository = NotificationRepository();
        await repository.bulkDeleteNotifications(unreadIds);
      }
      
      // Local state'i güncelle
      markAllAsRead();
    } catch (e) {
      print('Tüm bildirimler okundu işaretlenirken hata: $e');
    }
  }

  // Test bildirimi ekle (geliştirme için)
  void addTestNotification() {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Test Bildirimi',
      message: 'Bu bir test bildirimidir. Web sitesi API\'si çalışıyor!',
      time: DateTime.now(),
      isRead: false,
      type: 'test',
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
    
    print('🧪 Test bildirimi eklendi. Toplam: $_unreadCount');
  }

}
