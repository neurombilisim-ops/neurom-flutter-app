import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData();

class MyTheme {
  /*configurable colors stars*/
  static Color mainColor = Color(0xffffffff); // beyaz arka plan
  static const Color accent_color = Color(0xff0091e5); // Vatan mavi
  static const Color accent_color_shadow =
      Color.fromRGBO(0, 145, 229, .40); // this color is a dropshadow of
  static Color soft_accent_color = Color.fromRGBO(0, 145, 229, 0.1); // light blue
  static Color splash_screen_color = Color.fromRGBO(
      0, 145, 229, 1); // bottom_header_bg_color
  
  // Vatan Computer renkleri
  static const Color top_header_bg_color = Color(0xffffffff); // Üst Başlık Arka Plan Rengi
  static const Color middle_header_bg_color = Color(0xffffffff); // Orta Başlık Arka Plan Rengi
  static const Color bottom_header_bg_color = Color(0xff0091e5); // Vatan mavi
  static const Color top_header_text_color = Color(0xff666666); // Üst Başlık Yazı Rengi
  static const Color middle_header_text_color = Color(0xff666666); // Orta Başlık Yazı Rengi
  static const Color bottom_header_text_color = Color(0xffffffff); // bottom_header_text_color
  
  // Vatan Computer özel renkleri
  static const Color vatan_blue = Color(0xff0091e5); // Vatan mavi
  static const Color vatan_red = Color(0xffe74c3c); // Vatan kırmızı
  static const Color vatan_dark_blue = Color(0xff0078d4); // Koyu mavi
  static const Color vatan_orange = Color(0xfff39c12); // Turuncu vurgu
  
  /*configurable colors ends*/
  /*If you are not a developer, do not change the bottom colors*/
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  static Color noColor = Color.fromRGBO(255, 255, 255, 0);
  static Color light_grey = Color.fromRGBO(239, 239, 239, 1);
  static Color dark_grey = Color.fromRGBO(107, 115, 119, 1);
  static Color medium_grey = Color.fromRGBO(167, 175, 179, 1);
  static Color blue_grey = Color.fromRGBO(168, 175, 179, 1);
  static Color medium_grey_50 = Color.fromRGBO(167, 175, 179, .5);
  static const Color grey_153 = Color.fromRGBO(153, 153, 153, 1);
  static Color dark_font_grey = Color(0xff857E7E); // Üst/Orta Başlık Yazı Rengi
  static const Color font_grey = Color(0xff857E7E); // Üst/Orta Başlık Yazı Rengi
  static const Color textfield_grey = Color.fromRGBO(209, 209, 209, 1);
  static const Color font_grey_Light = Color(0xff857E7E); // Üst/Orta Başlık Yazı Rengi
  static Color golden = Color.fromRGBO(255, 168, 0, 1);
  static Color amber = Color.fromRGBO(254, 234, 209, 1);
  static Color amber_medium = Color.fromRGBO(254, 240, 215, 1);
  static Color golden_shadow = Color.fromRGBO(255, 168, 0, .4);
  static Color green = Colors.green;
  static Color? green_light = Colors.green[200];
  static Color shimmer_base = Colors.grey.shade50;
  static Color shimmer_highlighted = Colors.grey.shade200;
  //testing shimmer
  /*static Color shimmer_base = Colors.redAccent;
  static Color shimmer_highlighted = Colors.yellow;*/

  // gradient color for coupons
  static const Color gigas = Color.fromRGBO(95, 74, 139, 1);
  static const Color polo_blue = Color.fromRGBO(152, 179, 209, 1);
  //------------
  static const Color blue_chill = Color.fromRGBO(71, 148, 147, 1);
  static const Color cruise = Color.fromRGBO(124, 196, 195, 1);
  //---------------
  static const Color brick_red = Color.fromRGBO(191, 25, 49, 1);
  static const Color cinnabar = Color.fromRGBO(226, 88, 62, 1);

  static TextTheme textTheme1 = TextTheme(
    bodyLarge: TextStyle(fontSize: 14),
    bodyMedium: TextStyle(fontSize: 12),
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    bodySmall: TextStyle(fontSize: 10),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
  );

  static LinearGradient buildLinearGradient3() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.polo_blue, MyTheme.gigas],
    );
  }

  static LinearGradient buildLinearGradient2() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.cruise, MyTheme.blue_chill],
    );
  }

  static LinearGradient buildLinearGradient1() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [MyTheme.cinnabar, MyTheme.brick_red],
    );
  }

  static BoxShadow commonShadow() {
    return BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      spreadRadius: 0.0,
      offset: Offset(0.0, 10.0),
    );
  }
}
