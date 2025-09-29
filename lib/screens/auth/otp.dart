import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/input_decorations.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/auth_helper.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../../main.dart';
import '../main.dart';

class Otp extends StatefulWidget {
  String? title;
  String? phone;
  String? from;
  Otp({super.key, this.title, this.phone, this.from});

  @override
  _OtpState createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  //controllers
  final TextEditingController _verificationCodeController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  onTapResend() async {
    try {
      print("E-posta doğrulama kodu tekrar gönderiliyor...");
      print("Access token: ${access_token.$}");
      
      var resendCodeResponse = await AuthRepository().getResendCodeResponse();
      
      print("Resend Code Response: ${resendCodeResponse.result}");
      print("Resend Code Message: ${resendCodeResponse.message}");
      
      if (resendCodeResponse.result == true) {
        ToastComponent.showDialog("Doğrulama kodu e-posta adresinize tekrar gönderildi.");
      } else {
        ToastComponent.showDialog("Doğrulama kodu gönderilemedi: ${resendCodeResponse.message}");
      }
    } catch (e) {
      print("Doğrulama kodu gönderme hatası: $e");
      ToastComponent.showDialog("Doğrulama kodu gönderilemedi: $e");
    }
  }


  onPressConfirm() async {
    var code = _verificationCodeController.text.toString();

    if (code == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_verification_code,
      );
      return;
    }

    var confirmCodeResponse = await AuthRepository().getConfirmCodeResponse(
      code,
    );

    if (!(confirmCodeResponse.result)) {
      ToastComponent.showDialog(confirmCodeResponse.message);
    } else {
      ToastComponent.showDialog(confirmCodeResponse.message);
      
      // E-posta doğrulandıktan sonra kullanıcıyı giriş yapmış olarak işaretle
      if (SystemConfig.systemUser != null) {
        SystemConfig.systemUser!.emailVerified = true;
        // Kullanıcıyı giriş yapmış olarak işaretle
        is_logged_in.$ = true;
        is_logged_in.save();
      }
      
      // E-posta doğrulandıktan sonra ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Main(),
        ),
      );
    }
  }

  PreferredSizeWidget _buildVatanStyleAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 70,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol tarafta geri butonu
          Container(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Image.asset(
                "assets/sol.png",
                width: 24,
                height: 24,
                color: Colors.black87,
              ),
            ),
          ),
          // Ortada logo
          Expanded(
            child: Image.asset(
              "assets/logo.png",
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          // Sağ tarafta boş alan (denge için)
          Container(
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildVatanStyleAppBar(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8F9FA),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  
                  // Başlık bölümü
                  _buildHeaderSection(),
                  SizedBox(height: 30),
                  
                  // Form bölümü
                  _buildFormSection(),
                  SizedBox(height: 20),
                  
                  // Doğrula butonu
                  _buildConfirmButton(),
                  SizedBox(height: 20),
                  
                  // Tekrar gönder bölümü
                  _buildResendSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Başlık
        Text(
          'E-posta Adresinizi Doğrulayın',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doğrulama kodu label
          Text(
            'Doğrulama Kodu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          
          // Bilgi kutusu
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF2196F3), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'E-posta adresinize doğrulama kodu gönderilmiştir. Kodu almadıysanız "Tekrar Gönder" butonuna basın.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Doğrulama kodu input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _verificationCodeController,
              autofocus: false,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE9ECEF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE9ECEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF0091e5), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: Icon(Icons.verified_user_outlined, color: Color(0xFF0091e5), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          onPressConfirm();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0091e5),
          elevation: 0,
          side: BorderSide(
            color: Color(0xFF0091e5),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.confirm_ucf,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Container(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          onTapResend();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF0091e5),
          side: BorderSide(color: Color(0xFF0091e5), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.resend_code_ucf,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  onTapLogout(context) {
    try {
      AuthHelper().clearUserData(); // Ensure this clears user data properly
      routes.push("/");
    } catch (e) {
      print('Error navigating to Main: $e');
    }
  }
}
