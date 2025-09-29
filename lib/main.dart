import 'dart:async';

import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/middlewares/auth_middleware.dart';
import 'package:neurom_bilisim_store/screens/auth/login.dart';
import 'package:neurom_bilisim_store/screens/filter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:shared_value/shared_value.dart';
import 'package:neurom_bilisim_store/services/local_notification_service.dart';
import 'package:neurom_bilisim_store/providers/notification_provider.dart';

import 'app_config.dart';
import 'custom/aiz_route.dart';
import 'other_config.dart';

import 'helpers/main_helpers.dart';
import 'lang_config.dart';
import 'my_theme.dart';
import 'services/installation_service.dart';
import 'presenter/cart_counter.dart';
import 'presenter/cart_provider.dart';
import 'presenter/currency_presenter.dart';
import 'presenter/home_presenter.dart';
import 'presenter/select_address_provider.dart';
import 'presenter/unRead_notification_counter.dart';
import 'providers/blog_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auction/auction_bidded_products.dart';
import 'screens/auction/auction_products.dart';
import 'screens/auction/auction_products_details.dart';
import 'screens/auction/auction_purchase_history.dart';
import 'screens/auth/registration.dart';
import 'screens/brand_products.dart';
import 'screens/category_list_n_product/category_list.dart';
import 'screens/category_list_n_product/category_products.dart';
import 'screens/checkout/cart.dart';
import 'screens/classified_ads/classified_ads.dart';
import 'screens/classified_ads/classified_product_details.dart';
import 'screens/classified_ads/classified_provider.dart';
import 'screens/classified_ads/my_classified_ads.dart';
import 'screens/coupon/coupons.dart';
import 'screens/flash_deal/flash_deal_list.dart';
import 'screens/flash_deal/flash_deal_products.dart';
import 'screens/followed_sellers.dart';
import 'screens/index.dart';
import 'screens/orders/order_details.dart';
import 'screens/orders/order_list.dart';
import 'screens/package/packages.dart';
import 'screens/product/product_details.dart';
import 'screens/product/todays_deal_products.dart';
import 'screens/profile.dart';
import 'screens/seller_details.dart';
import 'services/push_notification_service.dart';
import 'services/installation_service.dart';
import 'single_banner/photo_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Firebase Messaging başlat
  await _initializeFirebaseMessaging();
  
  // Local Notification Service başlat
  await LocalNotificationService.initialize();
  
  await FlutterDownloader.initialize(
    debug: true, // Optional: set to false to disable printing logs to console
    ignoreSsl:
        true, // Optional: set to false to disable working with HTTP links
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Android 15 uyumlu edge-to-edge desteği
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(SharedValue.wrapApp(MyApp()));
}

// Firebase Messaging başlatma fonksiyonu
Future<void> _initializeFirebaseMessaging() async {
  if (OtherConfig.USE_PUSH_NOTIFICATION) {
    // Bildirim izni kontrol et ve iste
    await _checkAndRequestNotificationPermission();
    
    // Installation ID al
    String? installationId = await InstallationService.getInstallationId();
    
    // FCM token al
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground mesaj alındı: ${message.notification?.title}');
      // Sistem bildirim alanında göster
      LocalNotificationService.showNotification(message);
      // Provider'a gerçek bildirimi ekle
      if (OneContext.hasContext) {
        Provider.of<NotificationProvider>(OneContext().context!, listen: false)
            .addNotification(message);
      }
    });
    
    // Notification tap handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Bildirim servisi ile işle
      // PushNotificationService.handleNotificationTap(message);
    });
  }
}

// Bildirim izni kontrol et ve iste
Future<void> _checkAndRequestNotificationPermission() async {
  try {
    final FirebaseMessaging fcm = FirebaseMessaging.instance;
    
    // Mevcut izin durumunu kontrol et
    NotificationSettings settings = await fcm.getNotificationSettings();
    
    // Eğer izin verilmemişse iste
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      
      // İzin iste
      settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
    }
    
  } catch (e) {
    print('❌ Bildirim izni kontrolü hatası: $e');
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background mesaj alındı: ${message.notification?.title}');
}


// Foreground bildirim gösterme fonksiyonu (eski)
void _showNotificationDialog(RemoteMessage message) {
  // Global context kullanarak bildirim göster
  if (OneContext.hasContext) {
    showDialog(
      context: OneContext().context!,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Üst kısım - Resim ve başlık
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MyTheme.vatan_blue,
                        MyTheme.vatan_dark_blue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Arka plan deseni
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CustomPaint(
                            painter: NotificationBackgroundPainter(),
                          ),
                        ),
                      ),
                      
                      // Kapatma butonu
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      
                      // İçerik
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Bildirim ikonu ve başlık
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message.notification?.title ?? 'Yeni Bildirim',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 8),
                              
                              // Zaman damgası
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Şimdi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // İçerik kısmı
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bildirim içeriği
                        Text(
                          message.notification?.body ?? 'Yeni bir bildirim var',
                          style: TextStyle(
                            color: MyTheme.dark_font_grey,
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Alt kısım - Butonlar
                        Row(
                          children: [
                            // Kapat butonu
                            Expanded(
                              child: Container(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MyTheme.light_grey,
                                    foregroundColor: MyTheme.dark_font_grey,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Kapat',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 12),
                            
                            // Görüntüle butonu
                            Expanded(
                              child: Container(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _handleNotificationAction(message);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MyTheme.vatan_blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Görüntüle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Bildirim aksiyon işleyicisi
void _handleNotificationAction(RemoteMessage message) {
  // Bildirim türüne göre yönlendirme
  String? data = message.data['type'];
  
  switch (data) {
    case 'order':
      // Sipariş sayfasına yönlendir
      print('Sipariş bildirimi - yönlendiriliyor');
      break;
    case 'product':
      // Ürün sayfasına yönlendir
      print('Ürün bildirimi - yönlendiriliyor');
      break;
    case 'promotion':
      // Kampanya sayfasına yönlendir
      print('Kampanya bildirimi - yönlendiriliyor');
      break;
    default:
      // Ana sayfaya yönlendir
      print('Genel bildirim - ana sayfaya yönlendiriliyor');
  }
}

var routes = GoRouter(
  overridePlatformDefaultLocation: false,
  navigatorKey: OneContext().key,
  initialLocation: "/",
  routes: [
    GoRoute(
      path: '/',
      name: "Home",
      pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage(child: Index()),
      routes: [
        GoRoute(
          path: "customer_products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: MyClassifiedAds()),
        ),
        GoRoute(
          path: "customer-products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: ClassifiedAds()),
        ),
        GoRoute(
          path: "customer-product/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: ClassifiedAdsDetails(slug: getParameter(state, "slug")),
          ),
        ),
        GoRoute(
          path: "product/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: ProductDetails(slug: getParameter(state, "slug")),
          ),
        ),
        GoRoute(
          path: "customer-packages",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: UpdatePackage()),
        ),
        GoRoute(
          path: "auction_product_bids",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuthMiddleware(AuctionBiddedProducts()).next(),
          ),
        ),
        GoRoute(
          path: "users/login",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Login()),
        ),
        GoRoute(
          path: "users/registration",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Registration()),
        ),
        GoRoute(
          path: "dashboard",
          name: "Profile",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              AIZRoute.rightTransition(Profile()),
        ),
        GoRoute(
          path: "auction-products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: AuctionProducts()),
        ),
        GoRoute(
          path: "auction-product/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuctionProductsDetails(
              slug: getParameter(state, "slug"),
            ),
          ),
        ),
        GoRoute(
          path: "auction/purchase_history",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuthMiddleware(AuctionPurchaseHistory()).next(),
          ),
        ),
        GoRoute(
          path: "brand/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (BrandProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "brands",
          name: "Brands",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Filter(selected_filter: "brands")),
        ),
        GoRoute(
          path: "cart",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: AuthMiddleware(Cart()).next()),
        ),
        GoRoute(
          path: "categories",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (CategoryList(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "category/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (CategoryProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "flash-deals",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (FlashDealList())),
        ),
        GoRoute(
          path: "flash-deal/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (FlashDealProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "followed-seller",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (FollowedSellers())),
        ),
        GoRoute(
          path: "purchase_history",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (OrderList())),
        ),
        GoRoute(
          path: "purchase_history/details/:id",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (OrderDetails(id: int.parse(getParameter(state, "id")))),
          ),
        ),
        GoRoute(
          path: "sellers",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (Filter(selected_filter: "sellers"))),
        ),
        GoRoute(
          path: "shop/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (SellerDetails(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "todays-deal",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (TodaysDealProducts())),
        ),
        GoRoute(
          path: "coupons",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (Coupons())),
        ),
      ],
    ),
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Firebase.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CartCounter()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SelectAddressProvider()),
        ChangeNotifierProvider(
          create: (_) => UnReadNotificationCounter(),
        ),
        ChangeNotifierProvider(create: (_) => CurrencyPresenter()),
        ChangeNotifierProvider(create: (_) => HomePresenter()),
        ChangeNotifierProvider(create: (_) => BlogProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => MyClassifiedProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, provider, snapshot) {
          return MaterialApp.router(
            routerConfig: routes,
            title: AppConfig.app_name,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: MyTheme.white,
              scaffoldBackgroundColor: MyTheme.white,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: GoogleFonts.robotoTextTheme(
                Theme.of(context).textTheme,
              ).apply(
                bodyColor: MyTheme.dark_font_grey,
                displayColor: MyTheme.dark_font_grey,
              ),
              scrollbarTheme: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all<bool>(false),
              ),
            ),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            locale: provider.locale,
            supportedLocales: LangConfig().supportedLocales(),
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (AppLocalizations.delegate.isSupported(deviceLocale!)) {
                return deviceLocale;
              }
              return const Locale('en');
            },
          );
        },
      ),
    );
  }
}

// Bildirim arka plan deseni için CustomPainter
class NotificationBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Daireler çiz
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.15,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.1,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.2),
      size.width * 0.08,
      paint,
    );
    
    // Çizgiler çiz
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      linePaint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.7, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
