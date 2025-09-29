import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/data_model/login_response.dart';
import 'package:neurom_bilisim_store/screens/auth/add_email.dart';

class EmailHelper {
  /// E-posta adresinin geçerli olup olmadığını kontrol eder
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Kullanıcının e-posta adresinin eksik olup olmadığını kontrol eder
  static bool isEmailMissing(User? user) {
    if (user == null) return true;
    return !isValidEmail(user.email);
  }

  /// Sosyal medya e-posta adresinin geçerli olup olmadığını kontrol eder
  static bool isSocialEmailValid(String? email) {
    if (email == null || email.isEmpty) return false;
    if (email == "null" || email == "twitter_user") return false;
    return isValidEmail(email);
  }

  /// E-posta adresinin güvenli olup olmadığını kontrol eder (geçici e-posta kontrolü)
  static bool isEmailSecure(String? email) {
    if (email == null || email.isEmpty) return false;
    
    // Geçici e-posta servislerini kontrol et
    final tempEmailDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'temp-mail.org',
      'throwaway.email',
    ];
    
    for (String domain in tempEmailDomains) {
      if (email.toLowerCase().contains(domain)) {
        return false;
      }
    }
    
    return true;
  }

  /// E-posta adresinin formatını düzeltir
  static String? cleanEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    
    // Boşlukları temizle
    email = email.trim();
    
    // "null" string'ini kontrol et
    if (email == "null" || email == "twitter_user") return null;
    
    // Geçerli e-posta formatını kontrol et
    if (!isValidEmail(email)) return null;
    
    return email;
  }

  /// Sosyal medya kullanıcı verilerinden e-posta adresini çıkarır
  static String? extractEmailFromSocialData(Map<String, dynamic> userData) {
    // Farklı sosyal medya platformlarından e-posta adresini çıkarma
    String? email = userData['email'];
    
    if (email == null || email.isEmpty) {
      // Alternatif e-posta alanlarını kontrol et
      email = userData['email_address'];
    }
    
    if (email == null || email.isEmpty) {
      email = userData['primary_email'];
    }
    
    return cleanEmail(email);
  }

  /// E-posta eksikse kullanıcıyı e-posta ekleme sayfasına yönlendir
  static void redirectToAddEmailIfNeeded(
    BuildContext context,
    User? user,
    String? name,
    String? provider,
    String? socialProvider,
    String? accessToken,
    String? secretToken,
  ) {
    if (isEmailMissing(user)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEmailScreen(
            name: name,
            provider: provider,
            socialProvider: socialProvider,
            accessToken: accessToken,
            secretToken: secretToken,
          ),
        ),
      );
    }
  }
}
