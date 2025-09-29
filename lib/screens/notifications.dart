import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // API'den bildirimleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotificationsFromAPI();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: () => _markAllAsRead(provider),
                child: Text(
                  'Tümünü Okundu İşaretle',
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return provider.notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return _buildNotificationCard(notification, provider);
                  },
                );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Firebase Console\'dan bildirim gönderdiğinizde\nburada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Firebase Console → Messaging → Send message',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, NotificationProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onNotificationTap(notification, provider),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bildirim ikonu
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                // Bildirim içeriği
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatTime(notification.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'product':
        return Colors.blue;
      case 'order':
        return Colors.green;
      case 'promotion':
        return Colors.orange;
      case 'account':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.shopping_bag;
      case 'order':
        return Icons.local_shipping;
      case 'promotion':
        return Icons.local_offer;
      case 'account':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _onNotificationTap(NotificationItem notification, NotificationProvider provider) {
    // Bildirimi okundu olarak işaretle
    provider.markAsRead(notification.id);

    // Bildirim türüne göre yönlendirme
    switch (notification.type) {
      case 'product':
        // Ürün sayfasına yönlendir
        break;
      case 'order':
        // Sipariş detay sayfasına yönlendir
        break;
      case 'promotion':
        // Kampanya sayfasına yönlendir
        break;
      case 'account':
        // Profil sayfasına yönlendir
        break;
    }
  }

  void _markAllAsRead(NotificationProvider provider) async {
    await provider.markAllAsReadAPI();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tüm bildirimler okundu olarak işaretlendi'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
}
