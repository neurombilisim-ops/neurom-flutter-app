
import 'dart:convert';

import 'package:neurom_bilisim_store/custom/box_decorations.dart';
import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/input_decorations.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/file_helper.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final ScrollController _mainScrollController = ScrollController();

  final TextEditingController _nameController =
      TextEditingController(text: "${user_name.$}");

  final TextEditingController _phoneController =
      TextEditingController(text: user_phone.$);

  final TextEditingController _emailController =
      TextEditingController(text: user_email.$);
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  //for image uploading
  final ImagePicker _picker = ImagePicker();
  XFile? _file;

  // ------------------- CORRECTED FUNCTION -------------------
  chooseAndUploadImage(context) async {
    // --- START: Prominent Disclosure Dialog ---
    // This is the custom pop-up that Google requires.
    // It explains WHY you need the permission BEFORE you ask for it.
    bool? userAgreed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.photo_permission_ucf),
        // This is the most important part for Google's policy.
        content: Text(
            "To set your profile picture, this app needs to collect your image from the gallery."),
        actions: <Widget>[
          TextButton(
            // If user cancels, do nothing.
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.deny_ucf),
          ),
          TextButton(
            // If user agrees, proceed.
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Agree"),
          ),
        ],
      ),
    );
    // --- END: Prominent Disclosure Dialog ---

    // If the user did not agree in the dialog, stop here.
    if (userAgreed == null || !userAgreed) {
      ToastComponent.showDialog("Permission denied to access photos.");
      return;
    }

    // User has agreed. Now, you can pick the image.
    // The 'image_picker' package will handle the system permission request itself.
    _file = await _picker.pickImage(source: ImageSource.gallery);

    if (_file == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.no_file_is_chosen,
      );
      return;
    }

    // The rest of your original upload logic is correct and remains the same.
    String base64Image = FileHelper.getBase64FormateFile(_file!.path);
    String fileName = _file!.path.split("/").last;

    var profileImageUpdateResponse =
        await ProfileRepository().getProfileImageUpdateResponse(
      base64Image,
      fileName,
    );

    if (profileImageUpdateResponse.result == false) {
      ToastComponent.showDialog(
        profileImageUpdateResponse.message,
      );
      return;
    } else {
      ToastComponent.showDialog(
        profileImageUpdateResponse.message,
      );

      // Profil fotoğrafını güncelle
      avatar_original.$ = profileImageUpdateResponse.path;
      
      // Cache'i temizle ve kullanıcı verilerini yeniden yükle
      await _loadUserData();
      
      // UI'yi güncelle
      setState(() {});
      
      // Ek güvenlik için kısa bir gecikme sonrası tekrar güncelle
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {});
      });
    }
  }
  // ------------------- END OF CORRECTION -------------------

  Future<void> _onPageRefresh() async {}

  Future<void> _loadUserData() async {
    // Sadece UI'yi güncelle, veriler zaten güncellenmiş durumda
    setState(() {});
  }

  onPressUpdate() async {
    var name = _nameController.text.toString();
    var phone = _phoneController.text.toString();

    if (name == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name);
      return;
    }
    if (phone == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    }

    var postBody = jsonEncode({"name": name, "phone": phone});

    var profileUpdateResponse = await ProfileRepository()
        .getProfileUpdateResponse(post_body: postBody);

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message);

      user_name.$ = name;
      user_phone.$ = phone;
      setState(() {});
    }
  }

  onPressUpdatePassword() async {
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    var changePassword = password != "" || passwordConfirm != "";

    if (!changePassword && password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    }
    if (!changePassword && passwordConfirm == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    }
    if (changePassword && password.length < 6) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!
            .password_must_contain_at_least_6_characters,
      );
      return;
    }
    if (changePassword && password != passwordConfirm) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    }

    var postBody = jsonEncode({"password": password});

    var profileUpdateResponse = await ProfileRepository()
        .getProfileUpdateResponse(post_body: postBody);

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: buildBody(context),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: MyTheme.dark_grey,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.edit_profile_ucf,
        style: const TextStyle(
            fontSize: 16,
            color: Color(0xff3E4447),
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildBody(context) {
    if (is_logged_in.$ == false) {
      return SizedBox(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.please_log_in_to_see_the_profile,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        displacement: 10,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                buildTopSection(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                buildProfileForm(context)
              ]),
            )
          ],
        ),
      );
    }
  }

  buildTopSection() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(100.0)),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: "${avatar_original.$}?t=${DateTime.now().millisecondsSinceEpoch}",
                      fit: BoxFit.fill,
                    )),
              ),
              Positioned(
                right: 2,
                bottom: 0,
                child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Btn.basic(
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        chooseAndUploadImage(context);
                      },
                      shape: const CircleBorder(),
                      color: MyTheme.accent_color,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    )),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Profil Fotoğrafınızı Değiştirin",
            style: TextStyle(
              fontSize: 14,
              color: MyTheme.dark_grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  buildProfileForm(context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildBasicInfo(context),
          buildChangePassword(context),
        ],
      ),
    );
  }

  Widget buildChangePassword(context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: MyTheme.accent_color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LangText(context).local.password_changes_ucf,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xff2C3E50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.new_password_ucf,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB))),
            height: 48,
            child: TextField(
              style: const TextStyle(fontSize: 14, color: Color(0xff374151)),
              controller: _passwordController,
              autofocus: false,
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "Yeni şifrenizi girin")
                  .copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyTheme.accent_color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: InkWell(
                  onTap: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  child: Icon(
                    _showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: MyTheme.accent_color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!
                .password_must_contain_at_least_6_characters,
            style: const TextStyle(
                color: Color(0xff6B7280), 
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.retype_password_ucf,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB))),
            height: 48,
            child: TextField(
              controller: _passwordConfirmController,
              autofocus: false,
              obscureText: !_showConfirmPassword,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(fontSize: 14, color: Color(0xff374151)),
              decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "Şifrenizi tekrar girin")
                  .copyWith(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MyTheme.accent_color, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: InkWell(
                        onTap: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                        child: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: MyTheme.accent_color,
                        ),
                      )),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                onPressUpdatePassword();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Şifreyi Güncelle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBasicInfo(context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: MyTheme.accent_color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.basic_information_ucf,
                style: const TextStyle(
                    color: Color(0xff2C3E50),
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.name_ucf,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB))),
            height: 48,
            child: TextField(
              controller: _nameController,
              autofocus: false,
              style: const TextStyle(color: Color(0xff374151), fontSize: 14),
              decoration:
                  InputDecorations.buildInputDecoration_1(hint_text: "Adınız ve soyadınız")
                      .copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyTheme.accent_color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.phone_ucf,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB))),
            height: 48,
            child: TextField(
              controller: _phoneController,
              autofocus: false,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xff374151), fontSize: 14),
              decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "+90 5xx xxx xx xx")
                  .copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyTheme.accent_color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.email_ucf,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB))),
            height: 48,
            child: TextField(
              controller: _emailController,
              autofocus: false,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xff374151), fontSize: 14),
              decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "E-posta adresiniz")
                  .copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyTheme.accent_color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                onPressUpdate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Bilgileri Güncelle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
