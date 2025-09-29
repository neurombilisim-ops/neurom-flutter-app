import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/input_decorations.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/data_model/login_response.dart';
import 'package:neurom_bilisim_store/helpers/auth_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:neurom_bilisim_store/screens/auth/otp.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'dart:convert';

class AddEmailScreen extends StatefulWidget {
  final String? name;
  final String? provider;
  final String? socialProvider;
  final String? accessToken;
  final String? secretToken;

  const AddEmailScreen({
    Key? key,
    this.name,
    this.provider,
    this.socialProvider,
    this.accessToken,
    this.secretToken,
  }) : super(key: key);

  @override
  _AddEmailScreenState createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends State<AddEmailScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF0091e5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: Text(
        'E-posta Ekle',
        style: TextStyle(
          color: MyTheme.font_grey,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      titleSpacing: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Modern kart tasarımı
              Container(
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
                    // Başlık
                    Text(
                      'E-posta Adresinizi Ekleyin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Açıklama
                    Text(
                      'Ödeme yapabilmek ve hesabınızı güvende tutabilmek için e-posta adresinizi eklemeniz gerekiyor.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C757D),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 32),

                            // E-posta input
                            Text(
                              'E-posta Adresi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            SizedBox(height: 8),
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
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF0091e5), size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-posta adresi gerekli';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi girin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                    SizedBox(height: 24),

                            // Telefon numarası input
                            Text(
                              'Telefon Numarası (İsteğe Bağlı)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            SizedBox(height: 8),
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
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
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
                                  prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF0091e5), size: 20),
                                ),
                                validator: (value) {
                                  // Telefon numarası isteğe bağlı, boş bırakılabilir
                                  return null;
                                },
                              ),
                            ),
                    SizedBox(height: 32),

                    // E-posta ekle butonu
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0091e5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: Color(0xFF0091e5).withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Ekleniyor...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'E-posta Ekle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Bilgi notu
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF0091e5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF0091e5).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF0091e5),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'E-posta adresiniz sadece ödeme işlemleri ve önemli bildirimler için kullanılacaktır.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0091e5),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

        try {
          LoginResponse loginResponse;
          
          // Mevcut sosyal kullanıcının e-posta ve telefon bilgilerini güncelle
          try {
            // Önce e-posta güncelleme
            var emailPostBody = jsonEncode({"email": _emailController.text});
            var emailUpdateResponse = await ProfileRepository().getEmailUpdateResponse(post_body: emailPostBody);
          
          if (emailUpdateResponse.result == true) {
            // E-posta güncelleme başarılı, şimdi telefon numarası varsa onu da güncelle
            if (_phoneController.text.isNotEmpty) {
              var phonePostBody = jsonEncode({"phone": _phoneController.text});
              var phoneUpdateResponse = await ProfileRepository().getProfileUpdateResponse(post_body: phonePostBody);
              
              if (phoneUpdateResponse.result == true) {
                loginResponse = LoginResponse();
                loginResponse.result = true;
                loginResponse.message = "E-posta ve telefon numaranız başarıyla kaydedildi!";
                loginResponse.access_token = access_token.$;
                loginResponse.user = null;
                ToastComponent.showDialog("E-posta ve telefon numaranız başarıyla kaydedildi!");
              } else {
                loginResponse = LoginResponse();
                loginResponse.result = true; // E-posta başarılı, telefon başarısız
                loginResponse.message = "E-posta kaydedildi, telefon numarası kaydedilemedi.";
                loginResponse.access_token = access_token.$;
                loginResponse.user = null;
                ToastComponent.showDialog("E-posta kaydedildi, telefon numarası kaydedilemedi.");
              }
            } else {
              // Sadece e-posta güncellendi
              loginResponse = LoginResponse();
              loginResponse.result = true;
              loginResponse.message = "E-posta adresiniz başarıyla kaydedildi!";
              loginResponse.access_token = access_token.$;
              loginResponse.user = null;
              ToastComponent.showDialog("E-posta adresiniz başarıyla kaydedildi!");
            }
          } else {
            // E-posta güncelleme başarısız
            loginResponse = LoginResponse();
            loginResponse.result = false;
            loginResponse.message = emailUpdateResponse.message;
          }
          } catch (e) {
            loginResponse = LoginResponse();
            loginResponse.result = false;
            loginResponse.message = "Profil güncellenirken hata oluştu: $e";
          }

        if (loginResponse.result == true) {
          // E-posta başarıyla güncellendi, önce OTP gönder sonra OTP sayfasına git
          try {
            print("E-posta güncelleme sonrası otomatik OTP gönderiliyor...");
            var resendCodeResponse = await AuthRepository().getResendCodeResponse();
            
            if (resendCodeResponse.result == true) {
              print("OTP başarıyla gönderildi");
              ToastComponent.showDialog("Doğrulama kodu e-posta adresinize gönderildi.");
            } else {
              print("OTP gönderilemedi: ${resendCodeResponse.message}");
              ToastComponent.showDialog("E-posta güncellendi ancak doğrulama kodu gönderilemedi.");
            }
          } catch (e) {
            print("OTP gönderme hatası: $e");
            ToastComponent.showDialog("E-posta güncellendi ancak doğrulama kodu gönderilemedi.");
          }
          
          // OTP sayfasına git
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Otp()),
          );
        } else {
          ToastComponent.showDialog(loginResponse.message ?? "E-posta eklenirken hata oluştu");
        }
        } catch (e) {
          ToastComponent.showDialog("E-posta eklenirken hata oluştu: $e");
        } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
