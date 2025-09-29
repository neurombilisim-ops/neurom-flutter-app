import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InstallationService {
  static const String _installationIdKey = 'installation_id';
  
  // Installation ID al (Android ID + SharedPreferences)
  static Future<String?> getInstallationId() async {
    try {
      // Önce SharedPreferences'tan kontrol et
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString(_installationIdKey);
      
      if (savedId != null && savedId.isNotEmpty) {
        return savedId;
      }
      
      // Yoksa yeni ID oluştur (Firebase Installation ID formatı)
      var uuid = Uuid();
      String installationId = uuid.v4(); // Firebase Installation ID formatı
      
      // Kaydet
      await prefs.setString(_installationIdKey, installationId);
      
      return installationId;
    } catch (e) {
      print('Installation ID alınamadı: $e');
      return null;
    }
  }
  
  // Installation ID'yi yenile
  static Future<String?> refreshInstallationId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_installationIdKey);
      
      String? newId = await getInstallationId();
      return newId;
    } catch (e) {
      print('Installation ID yenilenemedi: $e');
      return null;
    }
  }
  
}
