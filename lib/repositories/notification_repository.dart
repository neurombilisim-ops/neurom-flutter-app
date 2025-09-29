import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';

class NotificationRepository {
  // Tüm bildirimleri getir
  Future<Map<String, dynamic>> getAllNotifications() async {
    String url = "${AppConfig.BASE_URL}/v2/all-notification";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );

    print("Get All Notifications API Response: ${response.body}");
    return jsonDecode(response.body);
  }

  // Okunmamış bildirimleri getir
  Future<Map<String, dynamic>> getUnreadNotifications() async {
    String url = "${AppConfig.BASE_URL}/v2/unread-notifications";
    print("🔔 API URL: $url");
    print("🔔 Token: ${access_token.$}");
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );

    print("🔔 Get Unread Notifications API Response: ${response.body}");
    print("🔔 Status Code: ${response.statusCode}");
    return jsonDecode(response.body);
  }

  // Bildirimi okundu olarak işaretle
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    String url = "${AppConfig.BASE_URL}/v2/notifications/mark-as-read?notification_id=$notificationId";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );

    print("Mark Notification As Read API Response: ${response.body}");
    return jsonDecode(response.body);
  }

  // Toplu bildirim silme
  Future<Map<String, dynamic>> bulkDeleteNotifications(List<String> notificationIds) async {
    String url = "${AppConfig.BASE_URL}/v2/notifications/bulk-delete";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
      body: jsonEncode({
        "notification_ids": "[${notificationIds.join(',')}]",
      }),
    );

    print("Bulk Delete Notifications API Response: ${response.body}");
    return jsonDecode(response.body);
  }

  // Eski API uyumluluğu için eksik fonksiyonlar
  Future<Map<String, dynamic>> getAllNotification() async {
    return await getAllNotifications();
  }

  Future<Map<String, dynamic>> getUnreadNotification() async {
    return await getUnreadNotifications();
  }

  Future<Map<String, dynamic>> notificationBulkDelete(List<String> notificationIds) async {
    return await bulkDeleteNotifications(notificationIds);
  }
}