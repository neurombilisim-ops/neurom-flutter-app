import 'package:neurom_bilisim_store/custom/aiz_route.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/auth_helper.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';

import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/auth_repository.dart';
import 'package:neurom_bilisim_store/screens/change_language.dart';
import 'package:neurom_bilisim_store/screens/currency_change.dart';
import 'package:neurom_bilisim_store/screens/home.dart';
import 'package:neurom_bilisim_store/screens/profile_edit.dart';
import 'package:neurom_bilisim_store/screens/address.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late BuildContext loadingContext;

  @override
  Widget build(BuildContext context) {
    return buildView(context);
  }

  Widget buildView(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.light_grey,
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 20,
            color: MyTheme.dark_font_grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: MyTheme.dark_font_grey),
        ),
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Dil ve Para Birimi Kartı
          _buildSettingsCard(
            title: "Genel Ayarlar",
            children: [
              _buildModernSettingItem(
                icon: Icons.language_outlined,
                title: AppLocalizations.of(context)!.language_ucf,
                subtitle: "Uygulama dili",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangeLanguage()),
                  );
                },
              ),
              _buildDivider(),
              _buildModernSettingItem(
                icon: Icons.attach_money_outlined,
                title: AppLocalizations.of(context)!.currency_ucf,
                subtitle: "Para birimi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CurrencyChange()),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Profil Ayarları Kartı
          _buildSettingsCard(
            title: "Profil Ayarları",
            children: [
              _buildModernSettingItem(
                icon: Icons.edit_outlined,
                title: AppLocalizations.of(context)!.edit_profile_ucf,
                subtitle: "Profil bilgilerini düzenle",
                onTap: () {
                  AIZRoute.push(context, ProfileEdit());
                },
              ),
              _buildDivider(),
              _buildModernSettingItem(
                icon: Icons.location_on_outlined,
                title: AppLocalizations.of(context)!.address_ucf,
                subtitle: "Adres bilgilerini yönet",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Address()),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Hesap Ayarları Kartı
          _buildSettingsCard(
            title: "Hesap Ayarları",
            children: [
              _buildModernSettingItem(
                icon: Icons.delete_outline,
                title: LangText(context).local.delete_my_account,
                subtitle: "Hesabınızı kalıcı olarak silin",
                isDestructive: true,
                onTap: () {
                  deleteWarningDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  deleteWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              LangText(context).local.delete_account_warning_title,
              style: TextStyle(fontSize: 15, color: MyTheme.dark_font_grey),
            ),
            content: Text(
              LangText(context).local.delete_account_warning_description,
              style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  pop(context);
                },
                child: Text(LangText(context).local.no_ucf),
              ),
              TextButton(
                onPressed: () {
                  pop(context);
                  deleteAccountReq(context);
                },
                child: Text(LangText(context).local.yes_ucf),
              ),
            ],
          ),
    );
  }

  deleteAccountReq(BuildContext context) async {
    if (!mounted) return; // Ensure the widget is still mounted

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ),
        );
      },
    );

    // Perform delete request
    var response = await AuthRepository().getAccountDeleteResponse();

    // If widget is not mounted, prevent further context-related actions
    if (!mounted) return;

    // Close loading dialog safely by checking if we can pop the context
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Close the loading dialog
    }

    // If deletion is successful, clear user data and navigate to home
    if (response.result) {
      AuthHelper().clearUserData();

      // Use post-frame callback to ensure navigation happens after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure the context is still valid before navigating
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // This ensures it's safe to pop the context
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Home()),
            (route) => false,
          );
        }
      });
    }

    // Show response message as toast
    ToastComponent.showDialog(response.message);
  }

  void pop(BuildContext context) {
    Navigator.of(context).pop();
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MyTheme.dark_font_grey,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : MyTheme.accent_color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : MyTheme.accent_color,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : MyTheme.dark_font_grey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: MyTheme.font_grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: MyTheme.font_grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: MyTheme.light_grey,
    );
  }

  SizedBox buildBottomVerticalCardListItem(
    String img,
    String label, {
    Function()? onPressed,
    bool isDisable = false,
  }) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Image.asset(
                img,
                height: 16,
                width: 16,
                color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios_rounded),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
