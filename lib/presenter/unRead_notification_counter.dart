import 'package:neurom_bilisim_store/repositories/notification_repository.dart';
import 'package:flutter/material.dart';

class UnReadNotificationCounter extends ChangeNotifier {
  int unReadNotificationCounter = 0;

  getCount() async {
    var res = await NotificationRepository().getUnreadNotification();
    unReadNotificationCounter = res['count'] ?? 0;
    notifyListeners();
  }
}
