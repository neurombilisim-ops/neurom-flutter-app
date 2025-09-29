import 'dart:io';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/google_recaptcha.dart';
import 'package:neurom_bilisim_store/custom/input_decorations.dart';
import 'package:neurom_bilisim_store/custom/intl_phone_input.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/other_config.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:neurom_bilisim_store/screens/auth/login.dart';
import 'package:neurom_bilisim_store/screens/common_webview_screen.dart';
import 'package:neurom_bilisim_store/screens/home.dart';
import 'package:neurom_bilisim_store/ui_elements/auth_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:validators/validators.dart';

import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../repositories/address_repository.dart';
import 'otp.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String _register_by = "email"; //phone or email
  String initialCountry = 'US';

  var countries_code = <String?>[];

  String? _phone = "";
  bool? _isAgree = false;
  bool _isCaptchaShowing = false;
  String googleRecaptchaKey = "";

  //controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
    fetch_country();
  }

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
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

  onPressSignUp() async {
    Loading.show(context);

    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    if (name == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name);
      return;
    } else if (_register_by == 'email' && (email == "" || !isEmail(email))) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      return;
    } else if (_register_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    } else if (passwordConfirm == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog(
        AppLocalizations.of(
          context,
        )!.password_must_contain_at_least_6_characters,
      );
      return;
    } else if (password != passwordConfirm) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    }

    var signupResponse = await AuthRepository().getSignupResponse(
      name,
      _register_by == 'email' ? email : _phone,
      password,
      passwordConfirm,
      _register_by,
      googleRecaptchaKey,
    );
    Loading.close();

    if (signupResponse.result == false) {
      var message = "";
      signupResponse.message.forEach((value) {
        message += value + "\n";
      });

      ToastComponent.showDialog(message);
    } else {
      ToastComponent.showDialog(signupResponse.message);
      AuthHelper().setUserData(signupResponse);

      // redirect to main
      // Navigator.pushAndRemoveUntil(context,
      //     MaterialPageRoute(builder: (context) {
      //       return Main();
      //     }), (newRoute) => false);
      // context.go("/");

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

        String? fcmToken = await fcm.getToken();

        print("--fcm token--");
        print(fcmToken);
        if (is_logged_in.$ == true) {
          // update device token
          var deviceTokenUpdateResponse = await ProfileRepository()
              .getDeviceTokenUpdateResponse(fcmToken!);
        }
      }

      // context.go("/");

      if ((mail_verification_status.$ && _register_by == "email") ||
          _register_by == "phone") {
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Home();
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen_height = MediaQuery.of(context).size.height;
    final screen_width = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
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
                child: buildBody(context, screen_width),
              ),
            ],
          ),
        ),
      ),
    );
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
        AppLocalizations.of(context)!.join_ucf,
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

  Column buildBody(BuildContext context, double screen_width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Text(
          'Hesap Oluşturun',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 12),
        
        // Açıklama
        Text(
          'E-posta veya telefon numaranız ile hesap oluşturabilirsiniz.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6C757D),
            height: 1.5,
          ),
        ),
        SizedBox(height: 32),

        // Form alanları
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İsim alanı
            Text(
              AppLocalizations.of(context)!.name_ucf,
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
                controller: _nameController,
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
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF0091e5), size: 20),
                ),
              ),
            ),
            SizedBox(height: 24),
            // E-posta/Telefon alanı
            Text(
              _register_by == "email"
                  ? AppLocalizations.of(context)!.email_ucf
                  : AppLocalizations.of(context)!.phone_ucf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 8),
            if (_register_by == "email")
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
                              _register_by = "phone";
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.or_register_with_a_phone,
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
                    child: CustomInternationalPhoneNumberInput(
                      countries: countries_code,
                      onInputChanged: (PhoneNumber number) {
                        print(number.phoneNumber);
                        setState(() {
                          _phone = number.phoneNumber;
                        });
                      },
                      onInputValidated: (bool value) {
                        print(value);
                      },
                      selectorConfig: SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: TextStyle(
                        color: MyTheme.font_grey,
                      ),
                      textFieldController: _phoneNumberController,
                      formatInput: true,
                      keyboardType: TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputDecoration: InputDecoration(
                        hintText: "01XXX XXX XXX",
                        hintStyle: TextStyle(color: Color(0xff6C757D)),
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
                      ),
                      onSaved: (PhoneNumber number) {
                        //print('On Saved: $number');
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
                            _register_by = "email";
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.or_register_with_an_email,
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
            SizedBox(height: 24),
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                AppLocalizations.of(context)!.password_must_contain_at_least_6_characters,
                style: TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Şifre onay alanı
            Text(
              AppLocalizations.of(context)!.retype_password_ucf,
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
                controller: _passwordConfirmController,
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
            SizedBox(height: 24),
            // Google reCAPTCHA
            if (google_recaptcha.$)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SizedBox(
                  height: _isCaptchaShowing ? 350 : 50,
                  width: 300,
                  child: Captcha(
                    (keyValue) {
                      googleRecaptchaKey = keyValue;
                      setState(() {});
                    },
                    handleCaptcha: (data) {
                      if (_isCaptchaShowing.toString() != data) {
                        _isCaptchaShowing = data;
                        setState(() {});
                      }
                    },
                  //  isIOS: Platform.isIOS,
                  ),
                ),
              ),

            // Şartlar ve koşullar
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
                      _isAgree = newValue;
                      setState(() {});
                    },
                    activeColor: Color(0xFF0091e5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Expanded(
                    child: RichText(
                      maxLines: 2,
                      text: TextSpan(
                        style: TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(text: "Şartlar ve koşulları kabul ediyorum "),
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
            SizedBox(height: 32),
            // Kayıt ol butonu
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAgree! ? () {
                  onPressSignUp();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAgree! ? Color(0xFF0091e5) : Color(0xFFE9ECEF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Color(0xFF0091e5).withOpacity(0.3),
                ),
                child: Text(
                  AppLocalizations.of(context)!.sign_up_ucf,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Zaten hesabınız var mı?
            Center(
              child: Text(
                AppLocalizations.of(context)!.already_have_an_account,
                style: TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Giriş yap butonu
            Container(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Login();
                      },
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF0091e5),
                  side: BorderSide(color: Color(0xFF0091e5), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.log_in,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
