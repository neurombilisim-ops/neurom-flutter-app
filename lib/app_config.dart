var this_year = DateTime.now().year.toString();

class AppConfig {
  //configure this
  static String copyright_text =
      "Neurom Bilişim Hizmetleri $this_year"; //this shows in the splash screen
  static String app_name =
      "Neurom "; //this shows in the splash screen
  static String home_app_name =
      "Neurom Market"; //this shows in the home page
  static String search_bar_text =
      "Ürün veya kategori ara"; //this will show in app Search bar.
  static String system_key =
      r"Q9z!fK3@uX7^pE1#hT5$Lb2%Nw8&Vr4*Zc6+Yd0"; //enter your purchase code for the app from codecanyon

  //Default language config
  static String default_language = "tr";
  static String mobile_app_code = "tr";
  static bool app_language_rtl = false;
  //configure this
  static const bool HTTPS =
      true; //if you are using localhost , set this to false
  //use only domain name without http:// or https://
  static const DOMAIN_PATH = "neurombilisim.com.tr";
  //do not configure these below
  static const String API_ENDPATH = "api/v2";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "$PROTOCOL$DOMAIN_PATH";
  static const String BASE_URL = "$RAW_BASE_URL/$API_ENDPATH";
}
