import 'dart:io';

import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/main.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/bottom_appbar_index.dart';
import 'package:neurom_bilisim_store/presenter/cart_counter.dart';
import 'package:neurom_bilisim_store/screens/auth/login.dart';
import 'package:neurom_bilisim_store/screens/category_list_n_product/category_list.dart';
import 'package:neurom_bilisim_store/screens/checkout/cart.dart';
import 'package:neurom_bilisim_store/screens/home.dart';
import 'package:neurom_bilisim_store/screens/profile.dart';
import 'package:neurom_bilisim_store/screens/wishlist/wishlist.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  Main({super.key, go_back = true, this.goToCategories = false});
  late bool go_back;
  final bool goToCategories;

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  var _children = [];
  CartCounter counter = CartCounter();
  BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();

  fetchAll() {
    getCartCount();
  }

  void onTapped(int i) {
    fetchAll();

    if (guest_checkout_status.$ && (i == 2)) {
    } else if (!guest_checkout_status.$ && (i == 2) && !is_logged_in.$) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
      });
      return;
    }

    // Favoriler sayfası için giriş kontrolü
    if (i == 3) {
      if (!is_logged_in.$) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
        });
        return;
      }
    }
    
    // Profil sayfası için giriş kontrolü
    if (i == 4) {
      if (!is_logged_in.$) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
        });
        return;
      }
    }
    
    // UI'yi güncelle
    setState(() {
      _currentIndex = i;
    });
  }



  getCartCount() async {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  @override
  void initState() {
    _children = [
      Home(),
      CategoryList(slug: "", is_base_category: true, is_top_category: true),
      Cart(
        has_bottomnav: true, 
        from_navigation: true, 
        counter: counter,
        onBackPressed: () => onTapped(0), // Ana sayfaya git
      ),
      Wishlist(),
      Profile(),
    ];
    
    if (widget.goToCategories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = 1;
        });
      });
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.initState();
  }


  bool _dialogShowing = false;

  Future<bool> willPop() async {
    print(_currentIndex);
    if (_currentIndex != 0) {
      fetchAll();
      setState(() {
        _currentIndex = 0;
      });
    } else {
      if (_dialogShowing) {
        return Future.value(false); // Dialog already showing, don't show again
      }
      setState(() {
        _dialogShowing = true;
      });

      final shouldPop =
          (await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Directionality(
                textDirection:
                    app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
                child: AlertDialog(
                  content: Text(
                    AppLocalizations.of(context)!.do_you_want_close_the_app,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Platform.isAndroid ? SystemNavigator.pop() : exit(0);
                      },
                      child: Text(AppLocalizations.of(context)!.yes_ucf),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text(AppLocalizations.of(context)!.no_ucf),
                    ),
                  ],
                ),
              );
            },
          )) ??
          false;

      setState(() {
        _dialogShowing = false; // Reset flag after dialog is closed
      });

      return shouldPop;
    }
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: willPop,
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          extendBody: false,
          body: _children[_currentIndex],
          bottomNavigationBar: _currentIndex == 2 ? null : SafeArea(
            child: Container(
              height: 80 + MediaQuery.of(context).padding.bottom, // Sistem padding'i ekle
              child: Stack(
              children: [
                // Ana navigasyon çubuğu
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Color(0xfff8f9fa),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        // Ana Sayfa
                        _buildNavItem(
                          icon: Icons.home,
                          label: AppLocalizations.of(context)!.home_ucf,
                          isSelected: _currentIndex == 0,
                          onTap: () => onTapped(0),
                          imageAsset: "assets/home.png",
                        ),
                        // Kategoriler
                        _buildNavItem(
                          icon: Icons.grid_view,
                          label: AppLocalizations.of(context)!.categories_ucf,
                          isSelected: _currentIndex == 1,
                          onTap: () => onTapped(1),
                          imageAsset: "assets/categories.png",
                        ),
                        // Boş alan (sepet butonu için)
                        SizedBox(width: 60),
                        // Favoriler
                        _buildNavItem(
                          icon: Icons.favorite_border,
                          label: "Favorilerim",
                          isSelected: _currentIndex == 3,
                          onTap: () => onTapped(3),
                          imageAsset: "assets/heart.png",
                        ),
                        // Profil
                        _buildNavItem(
                          icon: Icons.person,
                          label: "Profil",
                          isSelected: _currentIndex == 4,
                          onTap: () => onTapped(4),
                          imageAsset: "assets/profile.png",
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
                // Efektli sepet butonu - nav bar iconları ile tam hizalanmış
                Positioned(
                  top: 40, // Nav bar seviyesinde
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Ana Sayfa icon alanı (boş)
                      SizedBox(width: 60), // Nav bar ile aynı değer
                      // Kategoriler icon alanı (boş)
                      SizedBox(width: 60), // Nav bar ile aynı değer
                      // Sepet butonu - nav bar iconları ile tam hizalanmış
                      _buildFloatingCartButton(),
                      // Favoriler icon alanı (boş)
                      SizedBox(width: 60), // Nav bar ile aynı değer
                      // Profil icon alanı (boş)
                      SizedBox(width: 60), // Nav bar ile aynı değer
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? imageAsset,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imageAsset != null
                ? Image.asset(
                    imageAsset,
                    width: 25,
                    height: 25,
                    color: isSelected ? MyTheme.accent_color : Color.fromRGBO(153, 153, 153, 1),
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon,
                    color: isSelected ? MyTheme.accent_color : Color.fromRGBO(153, 153, 153, 1),
                    size: 25,
                  ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MyTheme.accent_color : Color.fromRGBO(153, 153, 153, 1),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    return GestureDetector(
      onTap: () => onTapped(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyTheme.accent_color,
              Color(0xff0078d4),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MyTheme.accent_color.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: MyTheme.accent_color.withOpacity(0.2),
              blurRadius: 30,
              offset: Offset(0, 12),
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          children: [
            // İkon tam ortada
            Center(
              child: Image.asset(
                "assets/cart.png",
                height: 28,
                width: 28,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
            if (Provider.of<CartCounter>(context, listen: true).cartCounter > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xffFF4757),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "${Provider.of<CartCounter>(context, listen: true).cartCounter}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


