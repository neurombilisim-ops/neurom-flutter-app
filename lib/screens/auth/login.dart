import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/input_decorations.dart';
import 'package:neurom_bilisim_store/custom/intl_phone_input.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/auth_helper.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/other_config.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:neurom_bilisim_store/screens/auth/password_forget.dart';
import 'package:neurom_bilisim_store/services/installation_service.dart';
import 'package:neurom_bilisim_store/screens/auth/registration.dart';
import 'package:neurom_bilisim_store/screens/common_webview_screen.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:neurom_bilisim_store/social_config.dart';
import 'package:neurom_bilisim_store/ui_elements/auth_ui.dart';
import 'package:neurom_bilisim_store/helpers/email_helper.dart';
import 'package:neurom_bilisim_store/screens/auth/add_email.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../custom/loading.dart';
import '../../repositories/address_repository.dart';
import '../../helpers/business_setting_helper.dart';
import 'otp.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "email"; //phone or email
  String initialCountry = 'US';

  // PhoneNumber phoneCode = PhoneNumber(isoCode: 'US', dialCode: "+1");
  var countries_code = <String?>[];

  String? _phone = "";
  bool? _isAgree = false;

  //controllers
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  // Password visibility
  bool _obscureText = true;
  
  // Tab selection
  int _selectedTab = 0; // 0: Giriş Yap, 1: Üye Ol, 2: Cep Telefonu
  late PageController _pageController;
  
  // Social login settings
  bool _allowGoogleLogin = false;
  bool _allowFacebookLogin = false;
  bool _allowTwitterLogin = false;
  bool _allowAppleLogin = false;

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    _pageController = PageController(initialPage: 0);
    super.initState();
    fetch_country();
    _loadSocialLoginSettings();
  }

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  _loadSocialLoginSettings() async {
    try {
      print('Sosyal medya ayarları yükleniyor...');
      
      await BusinessSettingHelper().setBusinessSettingData();
      
      // Local state'e kopyala
      _allowGoogleLogin = allow_google_login.$;
      _allowFacebookLogin = allow_facebook_login.$;
      _allowTwitterLogin = allow_twitter_login.$;
      _allowAppleLogin = allow_apple_login.$;
      
      print('Sosyal medya ayarları yüklendi. Google: $_allowGoogleLogin, Facebook: $_allowFacebookLogin, Twitter: $_allowTwitterLogin, Apple: $_allowAppleLogin');
      
      if (mounted) {
        setState(() {});
        print('UI güncellendi');
      }
    } catch (e) {
      print('Sosyal medya ayarları yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  onPressedLogin(ctx) async {
    FocusScope.of(context).unfocus();

    _showModernLoadingDialog("Giriş yapılıyor...");
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      return;
    } else if (_login_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    }

    var loginResponse = await AuthRepository().getLoginResponse(
      _login_by == 'email' ? email : _phone,
      password,
      _login_by,
    );
    Navigator.pop(context);

    // empty temp user id after logged in
    temp_user_id.$ = "";
    temp_user_id.save();

    if (loginResponse.result == false) {
      if (loginResponse.message.runtimeType == List) {
        ToastComponent.showDialog(loginResponse.message!.join("\n"));
        return;
      }
      ToastComponent.showDialog(loginResponse.message!.toString());
    } else {

      ToastComponent.showDialog(loginResponse.message!);

      AuthHelper().setUserData(loginResponse);

      // push notification starts
      if (OtherConfig.USE_PUSH_NOTIFICATION) {
        final FirebaseMessaging fcm = FirebaseMessaging.instance;

        await fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        String? fcmToken;
        try {
          fcmToken = await fcm.getToken();
        } catch (e) {
          print('Caught exception: $e');
        }

        // update device token
        if (fcmToken != null && is_logged_in.$) {
          try {
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken);
          } catch (e) {
          }
        }
      }

      // redirect
      if (loginResponse.user!.emailVerified!) {
        context.push("/");
      } else {
        if ((mail_verification_status.$ && _login_by == "email") ||
            (mail_verification_status.$ && _login_by == "phone")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Otp(
                  // verify_by: _register_by,
                  // user_id: signupResponse.user_id,
                );
              },
            ),
          );
        } else {
          context.push("/");
        }
      }
    }
  }

  onPressedFacebookLogin() async {
    try {
      final facebookLogin = await FacebookAuth.instance.login(
        loginBehavior: LoginBehavior.webOnly,
      );

      if (facebookLogin.status == LoginStatus.success) {
        // get the user data
        // by default we get the userId, email,name and picture
        final userData = await FacebookAuth.instance.getUserData();
        
        // E-posta adresini kontrol et
        String? email = EmailHelper.cleanEmail(userData['email']?.toString());
        
        var loginResponse = await AuthRepository().getSocialLoginResponse(
          "facebook",
          userData['name'].toString(),
          email ?? "",
          userData['id'].toString(),
          access_token: facebookLogin.accessToken!.tokenString,
        );
        
        if (loginResponse.result == false) {
          ToastComponent.showDialog(loginResponse.message!);
        } else {
          ToastComponent.showDialog(loginResponse.message!);
          AuthHelper().setUserData(loginResponse);
          
          // push notification starts
          if (OtherConfig.USE_PUSH_NOTIFICATION) {
            final FirebaseMessaging fcm = FirebaseMessaging.instance;

            await fcm.requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            );

            String? fcmToken;
            try {
              fcmToken = await fcm.getToken();
            } catch (e) {
              print('Caught exception: $e');
            }

            // update device token
            if (fcmToken != null && is_logged_in.$) {
              try {
                var deviceTokenUpdateResponse = await ProfileRepository()
                    .getDeviceTokenUpdateResponse(fcmToken);
              } catch (e) {
              }
            }
          }
          
          // Widget mounted kontrolü ile güvenli yönlendirme
          if (mounted) {
            // E-posta eksikse e-posta ekleme sayfasına yönlendir
            if (EmailHelper.isEmailMissing(loginResponse.user)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return AddEmailScreen(
                      name: userData['name']?.toString(),
                      provider: userData['id']?.toString(),
                      socialProvider: "facebook",
                      accessToken: facebookLogin.accessToken!.tokenString,
                    );
                  },
                ),
              );
            } else {
              // E-posta varsa ana sayfaya yönlendir
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Main();
                  },
                ),
              );
            }
          }
          FacebookAuth.instance.logOut();
        }
      } else {
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  onPressedGoogleLogin() async {
    try {
      print("Google giriş başlatılıyor...");
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        print("Google giriş iptal edildi");
        return;
      }

      print("Google kullanıcı bilgileri alındı: ${googleUser.email}");

      GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser.authentication;
      String? accessToken = googleSignInAuthentication.accessToken;

      if (accessToken == null) {
        print("Google access token alınamadı");
        ToastComponent.showDialog("Google giriş hatası: Access token alınamadı");
        return;
      }

      // E-posta adresini kontrol et
      String? email = EmailHelper.cleanEmail(googleUser.email);

      print("Google API'ye istek gönderiliyor...");
      var loginResponse = await AuthRepository().getSocialLoginResponse(
        "google",
        googleUser.displayName,
        email ?? "",
        googleUser.id,
        access_token: accessToken,
      );

      print("Google API yanıtı: ${loginResponse.result}");

      if (loginResponse.result == false) {
        print("Google giriş başarısız: ${loginResponse.message}");
        ToastComponent.showDialog(loginResponse.message!);
      } else {
        print("Google giriş başarılı");
        ToastComponent.showDialog(loginResponse.message!);
        AuthHelper().setUserData(loginResponse);
        
        // push notification starts
        if (OtherConfig.USE_PUSH_NOTIFICATION) {
          final FirebaseMessaging fcm = FirebaseMessaging.instance;

          await fcm.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

          String? fcmToken;
          try {
            fcmToken = await fcm.getToken();
          } catch (e) {
            print('FCM token hatası: $e');
          }

          // update device token
          if (fcmToken != null && is_logged_in.$) {
            try {
              var deviceTokenUpdateResponse = await ProfileRepository()
                  .getDeviceTokenUpdateResponse(fcmToken);
            } catch (e) {
              print('Device token güncelleme hatası: $e');
            }
          }
        }
        
        // Widget mounted kontrolü ile güvenli yönlendirme
        if (mounted) {
          // E-posta eksikse e-posta ekleme sayfasına yönlendir
          if (EmailHelper.isEmailMissing(loginResponse.user)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return AddEmailScreen(
                    name: googleUser.displayName,
                    provider: googleUser.id,
                    socialProvider: "google",
                    accessToken: accessToken,
                  );
                },
              ),
            );
          } else {
            print("E-posta mevcut, ana sayfaya yönlendiriliyor...");
            // E-posta varsa ana sayfaya yönlendir
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return Main();
                },
              ),
            );
          }
        }
      }
      GoogleSignIn().disconnect();
    } on Exception catch (e) {
      print("Google giriş hatası: $e");
      ToastComponent.showDialog("Google giriş hatası: ${e.toString()}");
    }
  }

  onPressedTwitterLogin() async {
    try {
      final twitterLogin = new TwitterLogin(
        apiKey: SocialConfig().twitter_consumer_key,
        apiSecretKey: SocialConfig().twitter_consumer_secret,
        redirectURI: 'neurombilisimstore://',
      );
      
      final authResult = await twitterLogin.login();
      
      if (authResult.status == TwitterLoginStatus.loggedIn) {
        
        // E-posta adresini kontrol et (Twitter genelde e-posta vermez)
        String? email = EmailHelper.cleanEmail(authResult.user!.email);
        if (email == null) {
          email = ""; // Twitter e-posta vermezse boş string gönder
        }
        
        var loginResponse = await AuthRepository().getSocialLoginResponse(
          "twitter",
          authResult.user!.name,
          email,
          authResult.user!.id.toString(),
          access_token: authResult.authToken,
          secret_token: authResult.authTokenSecret,
        );

        if (loginResponse.result == false) {
          ToastComponent.showDialog(loginResponse.message!);
        } else {
          ToastComponent.showDialog(loginResponse.message!);
          AuthHelper().setUserData(loginResponse);
          
          // push notification starts
          if (OtherConfig.USE_PUSH_NOTIFICATION) {
            final FirebaseMessaging fcm = FirebaseMessaging.instance;

            await fcm.requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            );

            String? fcmToken;
            try {
              fcmToken = await fcm.getToken();
            } catch (e) {
              print('Caught exception: $e');
            }

            // update device token
            if (fcmToken != null && is_logged_in.$) {
              try {
                var deviceTokenUpdateResponse = await ProfileRepository()
                    .getDeviceTokenUpdateResponse(fcmToken);
              } catch (e) {
              }
            }
          }
          
          // Widget mounted kontrolü ile güvenli yönlendirme
          if (mounted) {
            // E-posta eksikse e-posta ekleme sayfasına yönlendir
            if (EmailHelper.isEmailMissing(loginResponse.user)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return AddEmailScreen(
                      name: authResult.user!.name,
                      provider: authResult.user!.id.toString(),
                      socialProvider: "twitter",
                      accessToken: authResult.authToken,
                      secretToken: authResult.authTokenSecret,
                    );
                  },
                ),
              );
            } else {
              // E-posta varsa ana sayfaya yönlendir
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Main();
                  },
                ),
              );
            }
          }
        }
      } else {
        ToastComponent.showDialog("Twitter girişi başarısız oldu");
      }
    } on Exception catch (e) {
      print("Twitter login hatası: $e");
      ToastComponent.showDialog("Twitter girişi sırasında hata oluştu: $e");
    }
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  onPressedAppleLogin() async {
    await signInWithApple();
  }

  onPressedRegistration(ctx) async {
    FocusScope.of(context).unfocus();

    _showModernLoadingDialog("Hesap oluşturuluyor...");
    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    if (name == "") {
      Navigator.pop(context);
      ToastComponent.showDialog("İsim soyisim giriniz");
      return;
    } else if (_login_by == "email" && email == "") {
      Navigator.pop(context);
      ToastComponent.showDialog("E-posta adresini giriniz");
      return;
    } else if (_login_by == "phone" && _phone!.isEmpty) {
      Navigator.pop(context);
      ToastComponent.showDialog("Telefon numarasını giriniz");
      return;
    } else if (password == "") {
      Navigator.pop(context);
      ToastComponent.showDialog("Şifrenizi giriniz");
      return;
    } else if (passwordConfirm == "") {
      Navigator.pop(context);
      ToastComponent.showDialog("Şifre tekrarını giriniz");
      return;
    } else if (password != passwordConfirm) {
      Navigator.pop(context);
      ToastComponent.showDialog("Şifreler eşleşmiyor");
      return;
    }

    // Gerçek kayıt API'sini çağır
    var registrationResponse = await AuthRepository().getSignupResponse(
      name,
      _login_by == "email" ? email : _phone!,
      password,
      passwordConfirm, // password_confirmation
      _login_by, // "email" veya "phone"
      "", // captcha key (boş)
    );
    Navigator.pop(context);

    // Debug için response değerlerini yazdır

    if (registrationResponse.result == false) {
      if (registrationResponse.message.runtimeType == List) {
        ToastComponent.showDialog(registrationResponse.message!.join("\n"));
        return;
      }
      ToastComponent.showDialog(registrationResponse.message!.toString());
    } else {
      ToastComponent.showDialog(registrationResponse.message!);
      
      
      // Kayıt işleminde sadece geçici verileri kaydet, giriş yapma
      if (registrationResponse.result == true) {
        SystemConfig.systemUser = registrationResponse.user;
        // Geçici token'ı kaydet (OTP için gerekli)
        access_token.$ = registrationResponse.access_token;
        access_token.save();
        user_id.$ = registrationResponse.user?.id;
        user_id.save();
        user_name.$ = registrationResponse.user?.name;
        user_name.save();
        user_email.$ = registrationResponse.user?.email ?? "";
        user_email.save();
        user_phone.$ = registrationResponse.user?.phone ?? "";
        user_phone.save();
        avatar_original.$ = registrationResponse.user?.avatar_original;
        avatar_original.save();
        
      }
      
      // Her zaman OTP sayfasına git (kayıt işlemi için)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Otp(
            phone: _login_by == "phone" ? _phone : null,
            from: "signup",
          ),
        ),
      );
    }
  }

  // Modern loading diyalog göster
  void _showModernLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern loading animasyonu
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF004499)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Modern mesaj
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                // Alt açıklama
                Text(
                  "Lütfen bekleyin...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // E-posta doğrulama kodu gönderme fonksiyonu
  _sendVerificationEmail() async {
    try {
      var resendCodeResponse = await AuthRepository().getResendCodeResponse();
    } catch (e) {
    }
  }

  signInWithApple() async {
    try {
      print("Apple giriş başlatılıyor...");
      
      // To prevent replay attacks with the credential returned from Apple, we
      // include a nonce in the credential request.
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print("Apple kullanıcı bilgileri alındı: ${appleCredential.userIdentifier}");

      // Apple'dan gelen isim bilgisini birleştir
      String? fullName;
      if (appleCredential.givenName != null && appleCredential.familyName != null) {
        fullName = "${appleCredential.givenName} ${appleCredential.familyName}";
      } else if (appleCredential.givenName != null) {
        fullName = appleCredential.givenName;
      } else {
        fullName = "Apple User";
      }

      // E-posta adresini kontrol et
      String? email = EmailHelper.cleanEmail(appleCredential.email);

      print("Apple API'ye istek gönderiliyor...");
      var loginResponse = await AuthRepository().getSocialLoginResponse(
        "apple",
        fullName,
        email ?? "",
        appleCredential.userIdentifier,
        access_token: appleCredential.identityToken,
      );

      print("Apple API yanıtı: ${loginResponse.result}");

      if (loginResponse.result == false) {
        print("Apple giriş başarısız: ${loginResponse.message}");
        ToastComponent.showDialog(loginResponse.message!);
      } else {
        print("Apple giriş başarılı");
        ToastComponent.showDialog(loginResponse.message!);
        AuthHelper().setUserData(loginResponse);
        
        // push notification starts
        if (OtherConfig.USE_PUSH_NOTIFICATION) {
          final FirebaseMessaging fcm = FirebaseMessaging.instance;

          await fcm.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

          String? fcmToken;
          try {
            fcmToken = await fcm.getToken();
          } catch (e) {
            print('FCM token hatası: $e');
          }

          // update device token
          if (fcmToken != null && is_logged_in.$) {
            try {
              var deviceTokenUpdateResponse = await ProfileRepository()
                  .getDeviceTokenUpdateResponse(fcmToken);
            } catch (e) {
              print('Device token güncelleme hatası: $e');
            }
          }
        }
        
        // Widget mounted kontrolü ile güvenli yönlendirme
        if (mounted) {
          // E-posta eksikse e-posta ekleme sayfasına yönlendir
          if (EmailHelper.isEmailMissing(loginResponse.user)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return AddEmailScreen(
                    name: fullName,
                    provider: appleCredential.userIdentifier,
                    socialProvider: "apple",
                    accessToken: appleCredential.identityToken,
                  );
                },
              ),
            );
          } else {
            print("E-posta mevcut, ana sayfaya yönlendiriliyor...");
            // E-posta varsa ana sayfaya yönlendir
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return Main();
                },
              ),
            );
          }
        }
      }
    } on Exception catch (e) {
      print("Apple giriş hatası: $e");
      ToastComponent.showDialog("Apple giriş hatası: ${e.toString()}");
    }
  }

  PreferredSizeWidget _buildVatanStyleAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 92,
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
            child: Center(
              child: Image.asset(
                "assets/logo.png",
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Sağ tarafta boş alan (simetri için)
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
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              
              
              // Tab seçimi
              _buildTabSection(),
              SizedBox(height: 20),
              
              // Form bölümü
              SizedBox(
                height: _selectedTab == 0 ? 200 : _selectedTab == 1 ? 280 : 150, // Tab'a göre farklı yükseklik
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: _getFormForTab(),
                ),
              ),
              
              // Onay kutusu (sadece kayıt ol sayfasında)
              if (_selectedTab == 1) ...[
                _buildAgreementCheckbox(),
                SizedBox(height: 20),
              ],
              SizedBox(height: 20),
              
              // Şifremi unuttum (sadece giriş yap sayfasında)
              if (_selectedTab == 0) ...[
                _buildForgotPassword(),
                SizedBox(height: 20),
              ],
              
              // Butonlar
              _getButtonForTab(),
              SizedBox(height: 20),
              
              // Veya çizgisi ve sosyal medya girişi (sadece giriş yap sayfasında ve sosyal medya aktifse)
              if (_selectedTab == 0) ...[
                Builder(
                  builder: (context) {
                    bool showSocial = _allowGoogleLogin || _allowFacebookLogin || _allowTwitterLogin || (Platform.isIOS && _allowAppleLogin);
                    if (!showSocial) return SizedBox.shrink();
                    
                    return Column(
                      children: [
                        _buildDivider(),
                        SizedBox(height: 20),
                        _buildSocialLogin(),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context, double screen_width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Text(
          'Hesabınıza Giriş Yapın',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 12),
        
        // Açıklama
        Text(
          'E-posta veya telefon numaranız ile giriş yapabilirsiniz.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6C757D),
            height: 1.5,
          ),
        ),
        SizedBox(height: 32),

        // E-posta/Telefon seçimi
        Text(
          _login_by == "email"
              ? AppLocalizations.of(context)!.email_ucf
              : AppLocalizations.of(context)!.login_screen_phone,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 8),
        
        if (_login_by == "email")
          Column(
            children: [
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
                  controller: _emailController,
                  autofocus: false,
                  style: TextStyle(fontSize: 16),
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
                ),
              ),
              if (otp_addon_installed.$)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _login_by = "phone";
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)!.or_login_with_a_phone,
                        style: TextStyle(
                          color: Color(0xFF0091e5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
        else
          Column(
            children: [
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
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Telefon Numarası",
                    labelStyle: TextStyle(color: MyTheme.font_grey),
                    hintText: "5XX XXX XX XX",
                    hintStyle: TextStyle(color: Color(0xFFADB5BD)),
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
                  onChanged: (value) {
                    _phone = "+90" + value.replaceAll(" ", "");
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _login_by = "email";
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context)!.or_login_with_an_email,
                      style: TextStyle(
                        color: Color(0xFF0091e5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        
        SizedBox(height: 19),

        // Şifre alanı
        Text(
          AppLocalizations.of(context)!.password_ucf,
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
          child: TextField(
            controller: _passwordController,
            autofocus: false,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            style: TextStyle(fontSize: 16),
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
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF0091e5), size: 20),
            ),
          ),
        ),
        SizedBox(height: 27),

        // Giriş butonu
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              onPressedLogin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0091e5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Color(0xFF0091e5).withOpacity(0.3),
            ),
            child: Text(
              AppLocalizations.of(context)!.login_screen_log_in,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 19),

        // Kaydol bölümü
        Center(
          child: Text(
            "Hesabınız yok mu?",
            style: TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = 1;
            });
            _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          child: Text(
            "Kaydol",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0091e5),
            ),
          ),
        ),
        SizedBox(height: 32),

        // Sosyal medya girişi
        Builder(
          builder: (context) {
            print('Sosyal medya kontrolü - Google: $_allowGoogleLogin, Facebook: $_allowFacebookLogin, Twitter: $_allowTwitterLogin, Apple: $_allowAppleLogin');
            bool showSocial = _allowGoogleLogin || _allowFacebookLogin || _allowTwitterLogin || (Platform.isIOS && _allowAppleLogin);
            print('Sosyal medya gösterilecek mi: $showSocial');
            
            if (!showSocial) return SizedBox.shrink();
            
            return Column(
              children: [
              Center(
                child: Text(
                  "Sosyal Medya ile Giriş Yap",
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE9ECEF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_allowGoogleLogin)
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            onPressedGoogleLogin();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset("assets/google_logo.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_allowFacebookLogin)
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            onPressedFacebookLogin();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset("assets/facebook_logo.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_allowTwitterLogin)
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            onPressedTwitterLogin();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset("assets/twitter_logo.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (Platform.isIOS && _allowAppleLogin)
                      Container(
                        child: InkWell(
                          onTap: () async {
                            signInWithApple();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset("assets/apple_logo.png"),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
          },
        ),
      ],
    );
  }



  Widget _buildTabSection() {
    return Row(
      children: [
        // Giriş Yap Tab
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_selectedTab != 0) {
                setState(() {
                  _selectedTab = 0;
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              }
            },
            child: Column(
              children: [
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: _selectedTab == 0 ? Color(0xFF0066CC) : Color(0xFF6C757D),
                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                  child: Text(
                    "Giriş Yap",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 2,
                  width: double.infinity,
                  color: _selectedTab == 0 ? Color(0xFF0066CC) : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        // Üye Ol Tab
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_selectedTab != 1) {
                setState(() {
                  _selectedTab = 1;
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              }
            },
            child: Column(
              children: [
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: _selectedTab == 1 ? Color(0xFF0066CC) : Color(0xFF6C757D),
                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                  child: Text(
                    "Üye Ol",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 2,
                  width: double.infinity,
                  color: _selectedTab == 1 ? Color(0xFF0066CC) : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        // Cep Telefonu Tab
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_selectedTab != 2) {
                setState(() {
                  _selectedTab = 2;
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              }
            },
            child: Column(
              children: [
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: _selectedTab == 2 ? Color(0xFF0066CC) : Color(0xFF6C757D),
                    fontWeight: _selectedTab == 2 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                  child: Text(
                    "Cep Telefonu",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 2,
                  width: double.infinity,
                  color: _selectedTab == 2 ? Color(0xFF0066CC) : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tab'a göre form döndür
  Widget _getFormForTab() {
    switch (_selectedTab) {
      case 0:
        return _buildLoginForm();
      case 1:
        return _buildRegistrationFormWithoutAgreement();
      case 2:
        return _buildPhoneLoginForm();
      default:
        return _buildLoginForm();
    }
  }

  // Tab'a göre buton döndür
  Widget _getButtonForTab() {
    switch (_selectedTab) {
      case 0:
        return _buildLoginButton();
      case 1:
        return _buildRegisterButton();
      case 2:
        return _buildPhoneLoginButton();
      default:
        return _buildLoginButton();
    }
  }

  // Cep telefonu giriş formu
  Widget _buildPhoneLoginForm() {
    return Column(
      children: [
        SizedBox(height: 20),
        
        // Telefon numarası alanı
        Row(
          children: [
            // Ülke kodu
            Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "+90",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Telefon numarası
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Telefon Numarası",
                    labelStyle: TextStyle(color: Color(0xFF6C757D)),
                    hintText: "5XX XXX XX XX",
                    hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _phone = "+90" + value.replaceAll(" ", "");
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Şifre alanı
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: "Şifre",
              labelStyle: TextStyle(color: Color(0xFF6C757D)),
              hintText: "Şifrenizi girin",
              hintStyle: TextStyle(color: Color(0xFFADB5BD)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFF6C757D),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                // Şifre değiştiğinde UI'yi güncelle
              });
            },
          ),
        ),
        SizedBox(height: 16),
        
        // Açıklama metni
        Text(
          "Telefon numaranız ve şifreniz ile giriş yapın.",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6C757D),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Cep telefonu giriş butonu
  Widget _buildPhoneLoginButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_phone!.isEmpty || _passwordController.text.isEmpty) ? null : _onPhoneLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_phone!.isEmpty || _passwordController.text.isEmpty) ? Colors.grey[300] : Color(0xFF0066CC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          "Giriş Yap",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Telefon girişi buton işlevi
  void _onPhoneLoginPressed() async {
    if (_phone!.isEmpty) {
      ToastComponent.showDialog("Lütfen telefon numaranızı girin");
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      ToastComponent.showDialog("Lütfen şifrenizi girin");
      return;
    }
    
    // Modern loading göster
    _showModernLoadingDialog("Giriş yapılıyor...");
    
    try {
      // API'den telefon ile giriş yap
      var response = await AuthRepository().getPhoneLoginResponse(_phone!, _passwordController.text);
      
      // Loading'i kapat
      Navigator.pop(context);
      
      if (response.result == true) {
        // Başarılı giriş
        ToastComponent.showDialog(response.message ?? "Giriş başarılı");
        
        // Kullanıcı bilgilerini kaydet
        AuthHelper().setUserData(response);
        
        // Ana sayfaya yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Main()),
        );
      } else {
        // Hata mesajı göster
        ToastComponent.showDialog(response.message ?? "Giriş başarısız");
      }
    } catch (e) {
      // Loading'i kapat
      Navigator.pop(context);
      ToastComponent.showDialog("Bağlantı hatası: $e");
    }
  }

  Widget _buildRegistrationFormWithoutAgreement() {
    return Column(
      children: [
        SizedBox(height: 20), // Üst boşluk
        
        // İsim Soyisim alanı
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "İsim Soyisim",
            labelStyle: TextStyle(color: Color(0xFF6C757D)),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        SizedBox(height: 16),
        
        // E-posta veya Telefon seçimi
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _login_by = "email";
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _login_by == "email" ? Color(0xFF0066CC) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "E-posta",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _login_by == "email" ? Colors.white : Color(0xFF6C757D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _login_by = "phone";
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _login_by == "phone" ? Color(0xFF0066CC) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Telefon",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _login_by == "phone" ? Colors.white : Color(0xFF6C757D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // E-posta veya Telefon alanı
        if (_login_by == "email") ...[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "E-posta",
              labelStyle: TextStyle(color: Color(0xFF6C757D)),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ] else ...[
          // Telefon numarası alanı
          Row(
            children: [
              // Ülke kodu
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "+90",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Telefon numarası
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası",
                      labelStyle: TextStyle(color: Color(0xFF6C757D)),
                      hintText: "5XX XXX XX XX",
                      hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      _phone = "+90" + value.replaceAll(" ", "");
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 16),
        
        // Şifre alanı
        TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: "Şifre",
            labelStyle: TextStyle(color: Color(0xFF6C757D)),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF6C757D),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Şifre tekrar alanı
        TextField(
          controller: _passwordConfirmController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: "Şifre Tekrar",
            labelStyle: TextStyle(color: Color(0xFF6C757D)),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF6C757D),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementCheckbox() {
    return Column(
      children: [
        // Üyelik Aydınlatma Metni
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: null,
            overflow: TextOverflow.visible,
            text: TextSpan(
              style: TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
                height: 1.4,
              ),
              children: [
                TextSpan(text: "Üyelik Aydınlatma Metni ile ilgili açıklama için "),
                TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      String disclosureUrl = SystemConfig.membershipDisclosureUrl ?? 
                          "${AppConfig.RAW_BASE_URL}/mobile-page/uyelik-aydinlatma";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommonWebviewScreen(
                            page_name: "Üyelik Aydınlatma Metni",
                            url: disclosureUrl,
                          ),
                        ),
                      );
                    },
                  style: TextStyle(
                    color: Color(0xFF0091e5),
                    fontWeight: FontWeight.w600,
                  ),
                  text: "Üyelik Aydınlatma Formu",
                ),
                TextSpan(text: " sayfasını inceleyebilirsiniz."),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Kullanım sözleşmesi onay kutusu
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                value: _isAgree,
                onChanged: (newValue) {
                  setState(() {
                    _isAgree = newValue;
                  });
                },
                activeColor: Color(0xFF0091e5),
              ),
            ),
            SizedBox(width: 3),
            Expanded(
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  text: TextSpan(
                    style: TextStyle(
                      color: Color(0xFF6C757D),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  children: [
                    TextSpan(text: "Kullanım şartlarını ve gizlilik politikasını kabul ediyorum "),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          String termsUrl = SystemConfig.termsConditionsUrl ?? 
                              "${AppConfig.RAW_BASE_URL}/mobile-page/terms";
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommonWebviewScreen(
                                page_name: "Kullanım Şartları",
                                url: termsUrl,
                              ),
                            ),
                          );
                        },
                      style: TextStyle(
                        color: Color(0xFF0091e5),
                        fontWeight: FontWeight.w600,
                      ),
                      text: "Kullanım Şartları",
                    ),
                    TextSpan(text: " & "),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          String privacyUrl = SystemConfig.privacyPolicyUrl ?? 
                              "${AppConfig.RAW_BASE_URL}/mobile-page/privacy-policy";
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommonWebviewScreen(
                                page_name: "Gizlilik Politikası",
                                url: privacyUrl,
                              ),
                            ),
                          );
                        },
                      text: "Gizlilik Politikası",
                      style: TextStyle(
                        color: Color(0xFF0091e5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        SizedBox(height: 20), // Üst boşluk
        
        // E-posta alanı
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "E-Posta",
            labelStyle: TextStyle(color: Color(0xFF6C757D)),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        SizedBox(height: 16),
        
        // Şifre alanı
        TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: "Şifre",
            labelStyle: TextStyle(color: Color(0xFF6C757D)),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF6C757D),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PasswordForget()),
          );
        },
        child: Text(
          "Şifremi Unuttum",
          style: TextStyle(
            color: Color(0xFF0066CC),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () => onPressedLogin(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Color(0xFF0066CC),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "Giriş Yap",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066CC),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAgree! ? () {
          // Kayıt ol işlemi
          onPressedRegistration(context);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _isAgree! ? Color(0xFF0066CC) : Color(0xFF6C757D),
          elevation: 0,
          side: BorderSide(
            color: _isAgree! ? Color(0xFF0066CC) : Color(0xFFE9ECEF),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Kayıt Ol",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }


  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE9ECEF))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Veya",
            style: TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE9ECEF))),
      ],
    );
  }

  Widget _buildSocialLogin() {
    // Sosyal medya ayarlarını kontrol et
    bool showSocial = _allowGoogleLogin || _allowFacebookLogin || _allowTwitterLogin || (Platform.isIOS && _allowAppleLogin);
    
    // Eğer hiçbir sosyal medya girişi aktif değilse, boş widget döndür
    if (!showSocial) {
      return SizedBox.shrink();
    }

    List<Widget> socialButtons = [];
    
    // Aktif olan sosyal medya butonlarını ekle
    if (_allowGoogleLogin) {
      socialButtons.add(
        GestureDetector(
          onTap: () => onPressedGoogleLogin(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/google_logo.png",
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
      );
    }
    
    if (_allowFacebookLogin) {
      socialButtons.add(
        GestureDetector(
          onTap: () => onPressedFacebookLogin(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/facebook_logo.png",
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
      );
    }
    
    if (_allowTwitterLogin) {
      socialButtons.add(
        GestureDetector(
          onTap: () => onPressedTwitterLogin(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/twitter_logo.png",
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
      );
    }
    
    if (Platform.isIOS && _allowAppleLogin) {
      socialButtons.add(
        GestureDetector(
          onTap: () => onPressedAppleLogin(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/apple_logo.png",
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Sosyal medya logoları
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: socialButtons,
        ),
      ],
    );
  }
  

}
