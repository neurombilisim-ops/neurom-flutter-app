import 'dart:async';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  PackageInfo _packageInfo = PackageInfo(
    appName: AppConfig.app_name,
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    _initPackageInfo();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<Widget> loadFromFuture() async {

    return Future.value(Main());
  }

  @override
  Widget build(BuildContext context) {
    return CustomSplashScreen(
        seconds: 3,
      navigateAfterFuture: loadFromFuture(),
      title: Text(
        "V ${_packageInfo.version}",
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.white),
      ),
      useLoader: false,
      loadingText: Text(
        AppConfig.copyright_text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          color: Colors.white,
        ),
      ),
      image: Image.asset("assets/splash_screen_logo.png"),
      backgroundImage:
          Image.asset("assets/splash_login_registration_background_image.png"),
      backgroundColor: MyTheme.splash_screen_color,
      photoSize: 60.0,
      backgroundPhotoSize: 140.0,
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  final int? seconds;
  final Text? title;
  final Color? backgroundColor;

  final TextStyle? styleTextUnderTheLoader;
  final dynamic navigateAfterSeconds;
  final double? photoSize;
  final double? backgroundPhotoSize;
  final dynamic onClick;
  final Color? loaderColor;
  final Image? image;

  final Image? backgroundImage;

  final Text? loadingText;
  final ImageProvider? imageBackground;
  final Gradient? gradientBackground;

  final bool? useLoader;
  final Route? pageRoute;

  final String? routeName;

  /// expects a function that returns a future, when this future is returned it will navigate
  final Future<dynamic>? navigateAfterFuture;

  /// Use one of the provided factory constructors instead of.
  @protected
  const CustomSplashScreen({super.key, 
    this.loaderColor,
    this.navigateAfterFuture,
    this.seconds,
    this.photoSize,
    this.backgroundPhotoSize,
    this.pageRoute,
    this.onClick,
    this.navigateAfterSeconds,
    this.title = const Text(''),
    this.backgroundColor = Colors.white,
    this.styleTextUnderTheLoader = const TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
    this.image,
    this.backgroundImage,
    this.loadingText = const Text(""),
    this.imageBackground,
    this.gradientBackground,
    this.useLoader = true,
    this.routeName,
  });

  factory CustomSplashScreen.timer(
          {required int seconds,
          Color? loaderColor,
          Color? backgroundColor,
          double? photoSize,
          Text? loadingText,
          Image? image,
          Route? pageRoute,
          dynamic onClick,
          dynamic navigateAfterSeconds,
          Text? title,
          TextStyle? styleTextUnderTheLoader,
          ImageProvider? imageBackground,
          Gradient? gradientBackground,
          bool? useLoader,
          String? routeName}) =>
      CustomSplashScreen(
        loaderColor: loaderColor,
        seconds: seconds,
        photoSize: photoSize,
        loadingText: loadingText,
        backgroundColor: backgroundColor,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title,
        styleTextUnderTheLoader: styleTextUnderTheLoader,
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  factory CustomSplashScreen.network(
          {required Future<dynamic> navigateAfterFuture,
          Color? loaderColor,
          Color? backgroundColor,
          double? photoSize,
          double? backgroundPhotoSize,
          Text? loadingText,
          Image? image,
          Route? pageRoute,
          dynamic onClick,
          dynamic navigateAfterSeconds,
          Text? title,
          TextStyle? styleTextUnderTheLoader,
          ImageProvider? imageBackground,
          Gradient? gradientBackground,
          bool? useLoader,
          String? routeName}) =>
      CustomSplashScreen(
        loaderColor: loaderColor,
        navigateAfterFuture: navigateAfterFuture,
        photoSize: photoSize,
        backgroundPhotoSize: backgroundPhotoSize,
        loadingText: loadingText,
        backgroundColor: backgroundColor,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title,
        styleTextUnderTheLoader: styleTextUnderTheLoader,
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.routeName != null &&
        widget.routeName is String &&
        widget.routeName![0] != "/") {
      throw ArgumentError(
          "widget.routeName must be a String beginning with forward slash (/)");
    }
    if (widget.navigateAfterFuture == null) {
      Timer(Duration(seconds: widget.seconds!), () {
        if (widget.navigateAfterSeconds is String) {
          // It's fairly safe to assume this is using the in-built material
          // named route component
          Navigator.of(context)
              .pushReplacementNamed(widget.navigateAfterSeconds);
        } else if (widget.navigateAfterSeconds is Widget) {
          Navigator.of(context).pushReplacement(widget.pageRoute != null
              ? widget.pageRoute!
              : MaterialPageRoute(
                  settings: widget.routeName != null
                      ? RouteSettings(name: "${widget.routeName}")
                      : null,
                  builder: (BuildContext context) =>
                      widget.navigateAfterSeconds));
        } else {
          throw ArgumentError(
              'widget.navigateAfterSeconds must either be a String or Widget');
        }
      });
    } else {
      widget.navigateAfterFuture!.then((navigateTo) {
        if (navigateTo is String) {
          // It's fairly safe to assume this is using the in-built material
          // named route component
          Navigator.of(context).pushReplacementNamed(navigateTo);
        } else if (navigateTo is Widget) {
          Navigator.of(context).pushReplacement(widget.pageRoute != null
              ? widget.pageRoute!
              : MaterialPageRoute(
                  settings: widget.routeName != null
                      ? RouteSettings(name: "${widget.routeName}")
                      : null,
                  builder: (BuildContext context) => navigateTo));
        } else {
          throw ArgumentError(
              'widget.navigateAfterFuture must either be a String or Widget');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: InkWell(
          onTap: widget.onClick,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  image: widget.imageBackground == null
                      ? null
                      : DecorationImage(
                          fit: BoxFit.cover,
                          image: widget.imageBackground!,
                        ),
                  gradient: widget.gradientBackground,
                  color: widget.backgroundColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: widget.backgroundPhotoSize,
                    child: Hero(
                      tag: "backgroundImageInSplash",
                      child: Container(child: widget.backgroundImage),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 120.0),
                    child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 60.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: widget.photoSize,
                                child: Hero(
                                  tag: "splashscreenImage",
                                  child: Container(child: widget.image),
                                ),
                              ),
                            ),
                            widget.title!,
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                            ),
                            widget.loadingText!
                          ],
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
