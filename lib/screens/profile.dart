import 'dart:async';

import 'package:neurom_bilisim_store/custom/aiz_route.dart';
import 'package:neurom_bilisim_store/custom/box_decorations.dart';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/lang_text.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/auth_helper.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/unRead_notification_counter.dart';
import 'package:neurom_bilisim_store/repositories/profile_repository.dart';
import 'package:neurom_bilisim_store/screens/address.dart';
import 'package:neurom_bilisim_store/screens/auction/auction_products.dart';
import 'package:neurom_bilisim_store/screens/blog_list_screen.dart';
import 'package:neurom_bilisim_store/screens/classified_ads/classified_ads.dart';
import 'package:neurom_bilisim_store/screens/classified_ads/my_classified_ads.dart';
import 'package:neurom_bilisim_store/screens/coupon/coupons.dart';
import 'package:neurom_bilisim_store/screens/digital_product/digital_products.dart';
import 'package:neurom_bilisim_store/screens/filter.dart';
import 'package:neurom_bilisim_store/screens/product/last_view_product.dart';
import 'package:neurom_bilisim_store/screens/product/top_selling_products.dart';
import 'package:neurom_bilisim_store/screens/refund_request.dart';
import 'package:neurom_bilisim_store/screens/wholesales_screen.dart';
import 'package:neurom_bilisim_store/screens/wishlist/widgets/page_animation.dart';
import 'package:neurom_bilisim_store/screens/settings.dart';
import 'package:neurom_bilisim_store/screens/common_webview_screen.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:neurom_bilisim_store/app_config.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:route_transitions/route_transitions.dart';

import '../custom/btn.dart';
import '../repositories/auth_repository.dart';
import 'auction/auction_bidded_products.dart';
import 'auction/auction_purchase_history.dart';
import 'change_language.dart';
import 'chat/messenger_list.dart';
import 'club_point.dart';
import 'currency_change.dart';
import 'digital_product/purchased_digital_produts.dart';
import 'followed_sellers.dart';
import 'notification/notification_list.dart';
import 'orders/order_list.dart';
import 'profile_edit.dart';
import 'uploads/upload_file.dart';
import 'wallet.dart';
import 'wishlist/wishlist.dart';

class Profile extends StatefulWidget {
  Profile({Key? key, this.show_back_button = false}) : super(key: key);

  bool show_back_button;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _mainScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _auctionExpand = false;
  int? _cartCounter = 0;
  String _cartCounterString = "00";
  int? _wishlistCounter = 0;
  String _wishlistCounterString = "00";
  int? _orderCounter = 0;
  String _orderCounterString = "00";
  late BuildContext loadingcontext;

  @override
  void initState() {
    super.initState();
    
    // Giriş kontrolü - eğer kullanıcı giriş yapmamışsa ana sayfaya yönlendir
    if (!is_logged_in.$) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Main()),
          );
        }
      });
      return;
    }

    if (is_logged_in.$ == true) {
      fetchAll();
      // Profil bilgilerini güncelle
      _refreshUserData();
    }
  }

  // Profil bilgilerini yenile
  void _refreshUserData() async {
    try {
      var userByTokenResponse = await AuthRepository().getUserByTokenResponse();
      if (userByTokenResponse.result == true) {
        AuthHelper().setUserData(userByTokenResponse);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print("Profil bilgileri güncellenemedi: $e");
    }
  }

  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }


  onPopped(value) async {
    reset();
    fetchAll();
  }

  fetchAll() {
    fetchCounters();
    getNotificationCount();
  }

  getNotificationCount() async {
    Provider.of<UnReadNotificationCounter>(context, listen: false).getCount();
  }

  fetchCounters() async {
    var profileCountersResponse =
    await ProfileRepository().getProfileCountersResponse();

    _cartCounter = profileCountersResponse.cart_item_count;
    _wishlistCounter = profileCountersResponse.wishlist_item_count;
    _orderCounter = profileCountersResponse.order_count;

    _cartCounterString = counterText(
      _cartCounter.toString(),
      default_length: 2,
    );
    _wishlistCounterString = counterText(
      _wishlistCounter.toString(),
      default_length: 2,
    );
    _orderCounterString = counterText(
      _orderCounter.toString(),
      default_length: 2,
    );

    setState(() {});
  }

  deleteAccountReq() async {
    loading();
    var response = await AuthRepository().getAccountDeleteResponse();

    if (response.result) {
      AuthHelper().clearUserData();
      Navigator.pop(loadingcontext);
      _navigateToMain();
    }
    ToastComponent.showDialog(response.message);
  }

  String counterText(String txt, {default_length = 3}) {
    var blank_zeros = default_length == 3 ? "000" : "00";
    var leading_zeros = "";
    if (default_length == 3 && txt.length == 1) {
      leading_zeros = "00";
    } else if (default_length == 3 && txt.length == 2) {
      leading_zeros = "0";
    } else if (default_length == 2 && txt.length == 1) {
      leading_zeros = "0";
    }

    var newtxt = (txt == "" || txt == null.toString()) ? blank_zeros : txt;


    if (default_length > txt.length) {
      newtxt = leading_zeros + newtxt;
    }

    return newtxt;
  }

  reset() {
    _cartCounter = 0;
    _cartCounterString = "00";
    _wishlistCounter = 0;
    _wishlistCounterString = "00";
    _orderCounter = 0;
    _orderCounterString = "00";
    setState(() {});
  }

  List<int> listItem = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  _navigateToMain() {
    try {
      if (mounted) {
        // Ana sayfaya geri dön
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print("Ana sayfaya yönlendirme hatası: $e");
      // Hata durumunda yeni Main sayfası oluştur
      try {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Main()),
          (route) => false,
        );
      } catch (e2) {
        print("Root navigator ile yönlendirme hatası: $e2");
      }
    }
  }

  onTapLogout(BuildContext context) async {
    try {
      // API'ye çıkış yapma isteği gönder
      await AuthRepository().getLogoutResponse();
      
      // Yerel verileri temizle
      AuthHelper().clearUserData();
      
      // UI'yi güncelle
      setState(() {});
      
      // Başarı mesajı göster
      ToastComponent.showDialog("Başarıyla çıkış yaptınız");
      
      // Ana sayfaya yönlendir
      _navigateToMain();
    } catch (e) {
      print("Çıkış yapma hatası: $e");
      // Hata olsa bile yerel verileri temizle
      AuthHelper().clearUserData();
      
      // UI'yi güncelle
      setState(() {});
      
      // Ana sayfaya yönlendir
      _navigateToMain();
      ToastComponent.showDialog("Çıkış yapıldı");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer kullanıcı giriş yapmamışsa ana sayfayı göster
    if (!is_logged_in.$) {
      return Main();
    }
    
    return Directionality(
      textDirection:
      app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: buildView(context),
    );
  }

  Widget buildView(context) {
    return Container(
      color: Colors.white,
      height: DeviceInfo(context).height,
      child: Stack(
        children: [
          Container(
            height: DeviceInfo(context).height! / 2.5,
            width: DeviceInfo(context).width,
            color: MyTheme.accent_color,
            alignment: Alignment.topRight,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: buildCustomAppBar(context),
            body: buildBody(),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    return buildBodyChildren();
  }

  CustomScrollView buildBodyChildren() {
    return CustomScrollView(
      controller: _mainScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildAppbarSection(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildSettingAndAddonsHorizontalMenu(),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildLogoutButton(),
            ),
          ]),
        ),
      ],
    );
  }

  PreferredSize buildCustomAppBar(context) {
    return PreferredSize(
      preferredSize: Size(DeviceInfo(context).width!, 60),
      child: Container(
        child: SafeArea(
          child: Container(
            // Kapat butonu kaldırıldı
          ),
        ),
      ),
    );
  }



  showLoginWarning() {
    return ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
    );
  }

  deleteWarningDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              deleteAccountReq();
            },
            child: Text(LangText(context).local.yes_ucf),
          ),
        ],
      ),
    );
  }

  Widget buildSettingAndAddonsHorizontalMenu() {
    return Container(
      margin: EdgeInsets.only(top: 20), // Header ayrı bölümde olduğu için margin azaltıldı
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          buildMenuItem(
            Icons.shopping_bag_outlined,
            AppLocalizations.of(context)!.orders_ucf,
            is_logged_in.$
                ? () {
              Navigator.push(
                  context, PageAnimation.fadeRoute(OrderList()));
            }
                : () => showLoginWarning(),
          ),
          buildMenuItem(
            Icons.favorite_outline,
            "Beğendiklerim", // İstek listemi -> Beğendiklerim
            is_logged_in.$
                ? () {
              Navigator.push(
                  context, PageAnimation.fadeRoute(Wishlist()));
            }
                : () => showLoginWarning(),
          ),
          if (wallet_system_status.$)
            buildMenuItem(
              Icons.account_balance_wallet_outlined,
              AppLocalizations.of(context)!.my_wallet_ucf,
              is_logged_in.$
                  ? () {
                Navigator.push(context, PageAnimation.fadeRoute(Wallet()));
              }
                  : () => showLoginWarning(),
            ),
          buildMenuItem(
            Icons.location_on_outlined,
            "Adreslerim",
            is_logged_in.$
                ? () {
              Navigator.push(
                context,
                PageAnimation.fadeRoute(Address()),
              );
            }
                : () => showLoginWarning(),
          ),
          buildMenuItem(
            Icons.card_giftcard_outlined,
            "Kuponlarım", // Kuponlarım menüsü eklendi
            is_logged_in.$
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Coupons();
                  },
                ),
              );
            }
                : () => showLoginWarning(),
          ),
          buildMenuItem(
            Icons.settings_outlined,
            "Ayarlarım", // Hesap Ayarları -> Ayarlarım
            is_logged_in.$
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            }
                : () => showLoginWarning(),
          ),
          
          Container(
            height: 1,
            color: Color(0xffe9ecef),
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
          
          if (conversation_system_status.$)
            buildMenuItem(
              Icons.message_outlined,
              "Mesajlar", // Yardım Merkezi yerine Mesajlar
              is_logged_in.$
                  ? () {
                Navigator.push(
                  context,
                  PageAnimation.fadeRoute(MessengerList()),
                );
              }
                  : () => showLoginWarning(),
            ),
          buildMenuItem(
            Icons.privacy_tip_outlined,
            "Gizlilik",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CommonWebviewScreen(
                      url: "${AppConfig.RAW_BASE_URL}/mobile-page/privacy-policy",
                      page_name: "Gizlilik Politikası",
                    );
                  },
                ),
              );
            },
          ),
          buildMenuItem(
            Icons.info_outline,
            "Hakkında",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CommonWebviewScreen(
                      url: "${AppConfig.RAW_BASE_URL}/mobile-page/about-us",
                      page_name: "Hakkımızda",
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(IconData icon, String title, Function() onTap, {bool isLogout = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isLogout ? Colors.red : Color(0xff2C3E50),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Colors.red : Color(0xff2C3E50),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xff6c757d),
            ),
          ],
        ),
      ),
    );
  }

  Container buildSettingAndAddonsHorizontalMenuItem(
      String img,
      String text,
      Function() onTap,
      ) {
    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: is_logged_in.$
            ? onTap
            : () {
          showLoginWarning();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              img,
              width: 16,
              height: 16,
              color: is_logged_in.$
                  ? MyTheme.dark_font_grey
                  : MyTheme.medium_grey_50,
            ),
            SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: is_logged_in.$
                    ? MyTheme.dark_font_grey
                    : MyTheme.medium_grey_50,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildAppbarSection() {
    return Column(
        children: [
          Text(
          "Hesabım",
            style: TextStyle(
              fontSize: 18,
        color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: InkWell(
            onTap: () {
              if (!is_logged_in.$) {
                context.push("/users/login");
              }
            },
            child: Column(
        children: [
          Container(
                  width: 80,
                  height: 80,
            decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: MyTheme.accent_color, width: 3),
            ),
            child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
              child: Builder(
                builder: (context) {
                  if (is_logged_in.$ && avatar_original.$ != null && avatar_original.$!.isNotEmpty) {
                    String imageUrl = avatar_original.$!.startsWith('http') 
                        ? avatar_original.$! 
                        : "${AppConfig.BASE_URL}/${avatar_original.$!.replaceFirst('/', '')}";
                    
                    // Placeholder resmi kontrol et
                    if (imageUrl.contains('placeholder.jpg') || imageUrl.contains('placeholder.png')) {
                      return Image.asset(
                        'assets/profile_placeholder.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      );
                    }
                    
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        print("Loading avatar...");
                        return Image.asset(
                          'assets/profile_placeholder.png',
                                height: 80,
                                width: 80,
                          fit: BoxFit.cover,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Avatar Error: $error");
                        print("Avatar URL: $imageUrl");
                        return Image.asset(
                          'assets/profile_placeholder.png',
                                height: 80,
                                width: 80,
                          fit: BoxFit.cover,
                        );
                      },
                    );
                  } else {
                    print("Showing placeholder - conditions not met");
                    return Image.asset(
                      'assets/profile_placeholder.png',
                            height: 80,
                            width: 80,
                      fit: BoxFit.cover,
                    );
                  }
                },
              ),
            ),
          ),
                SizedBox(height: 10),
                // Kullanıcı adı
                buildUserInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget buildUserInfo() {
    return is_logged_in.$
        ? Text(
          "${user_name.$}",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
        : Text(
          "Hoş Geldiniz",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
  }

  Widget buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Çıkış yap işlemi
          _showLogoutDialog();
        },
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            "Çıkış Yap",
          style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Çıkış Yap"),
          content: Text("Hesabınızdan çıkmak istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onTapLogout(context);
              },
              child: Text("Çıkış Yap"),
            ),
          ],
        );
      },
    );
  }


  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingcontext = context;
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
  }
}
