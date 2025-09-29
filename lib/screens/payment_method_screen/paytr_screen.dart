import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
import 'package:neurom_bilisim_store/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../helpers/main_helpers.dart';
import '../profile.dart';

class PaytrScreen extends StatefulWidget {
  double? amount;
  String payment_type;
  String? payment_method_key;
  var package_id;
  int? orderId;
  PaytrScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.payment_type = "",
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  _PaytrScreenState createState() => _PaytrScreenState();
}

class _PaytrScreenState extends State<PaytrScreen> {
  int? _combined_order_id = 0;
  bool _order_init = false;
  String? _initial_url = "";
  bool _initial_url_fetched = false;
  bool _payment_processed = false; // Ödeme işlendi mi kontrolü

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      paytr();
    }
  }

  createOrder() async {
    var orderCreateResponse = await PaymentRepository().getOrderCreateResponse(
      widget.payment_method_key,
    );

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      Navigator.of(context).pop();
      return;
    }

    _combined_order_id = orderCreateResponse.combined_order_id;
    _order_init = true;
    setState(() {});
    paytr();
  }

  paytr() async {
    try {
      // PayTR API'den URL al - eski format
      String paytrUrl = "${AppConfig.BASE_URL}/paytr/init?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}";
      
      // Debug bilgileri (sadece önemli olanlar)
      print('PayTR URL: $paytrUrl');
      print('Amount: ${widget.amount}');
      
      final response = await http.get(
        Uri.parse(paytrUrl),
        headers: {
          ...commonHeader,
          ...authHeader,
        },
      );

      print('PayTR Response Status: ${response.statusCode}');
      print('PayTR Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        print('PayTR Response Data: $responseData');
        
        if (responseData['success'] == true) {
          // PayTR API'si farklı response yapısı döndürüyor
          if (responseData['data'] != null && responseData['data']['payment_url'] != null) {
            _initial_url = responseData['data']['payment_url'];
          } else if (responseData['url'] != null) {
            _initial_url = responseData['url'];
          }
          
          _initial_url_fetched = true;
          setState(() {});
          
          print('PayTR Initial URL: $_initial_url');
          
          if (_initial_url != null && _initial_url!.isNotEmpty) {
            try {
              _webViewController
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(Colors.white)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onWebResourceError: (error) {
                      print('WebView Error: ${error.description}');
                      if (mounted) {
                        ToastComponent.showDialog("WebView hatası: ${error.description}");
                      }
                    },
                    onPageStarted: (url) {
                      print('WebView Page Started: $url');
                      // Çok fazla redirect varsa durdur
                      if (url.contains('maxinet.isbank.com.tr') || 
                          url.contains('vakifbank.com.tr') || 
                          url.contains('bkm.com.tr')) {
                        print('Bank redirect detected, continuing...');
                      }
                    },
                    onPageFinished: (page) {
                      print('WebView Page Finished: $page');
                      if (page.contains("/paytr/success")) {
                        getData();
                      } else if (page.contains("/paytr/cancel")) {
                        if (mounted) {
                          ToastComponent.showDialog(
                            AppLocalizations.of(context)!.payment_cancelled_ucf,
                          );
                          Navigator.of(context).pop();
                        }
                        return;
                      }
                    },
                    onNavigationRequest: (request) {
                      print('Navigation Request: ${request.url}');
                      if (request.url.contains("/paytr/success") && !_payment_processed) {
                        print('PayTR Success URL detected, calling getData()');
                        _payment_processed = true; // Tekrar işlenmesini engelle
                        getData();
                        return NavigationDecision.prevent;
                      } else if (request.url.contains("/paytr/cancel") && !_payment_processed) {
                        print('PayTR Cancel URL detected');
                        _payment_processed = true; // Tekrar işlenmesini engelle
                        if (mounted) {
                          ToastComponent.showDialog(
                            AppLocalizations.of(context)!.payment_cancelled_ucf,
                          );
                          Navigator.of(context).pop();
                        }
                        return NavigationDecision.prevent;
                      }
                      return NavigationDecision.navigate;
                    },
                  ),
                );
              
              // URL'yi güvenli şekilde yükle
              await _webViewController.loadRequest(
                Uri.parse(_initial_url!),
                headers: {
                  "User-Agent": "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36",
                },
              );
            } catch (e) {
              print('WebView Load Error: $e');
              if (mounted) {
                ToastComponent.showDialog("WebView yükleme hatası: $e");
                Navigator.of(context).pop();
              }
            }
          } else {
            ToastComponent.showDialog("PayTR URL boş geldi!");
            Navigator.of(context).pop();
          }
        } else {
          String errorMessage = responseData['message'] ?? 'Bilinmeyen hata';
          print('PayTR API Error: $errorMessage');
          ToastComponent.showDialog("PayTR Hatası: $errorMessage");
          Navigator.of(context).pop();
        }
      } else {
        print('PayTR HTTP Error: ${response.statusCode} - ${response.body}');
        ToastComponent.showDialog("PayTR API hatası: ${response.statusCode}\n${response.body}");
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('PayTR Exception: $e');
      ToastComponent.showDialog("PayTR başlatma hatası: $e");
      Navigator.of(context).pop();
    }
  }

  getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
      print('WebView Response Data: $data');
      
      try {
        // Önce JSON olarak parse etmeye çalış
        var responseJSON = jsonDecode(data as String);
        if (responseJSON.runtimeType == String) {
          responseJSON = jsonDecode(responseJSON);
        }
        
        if (responseJSON["result"] == false) {
          ToastComponent.showDialog(responseJSON["message"]);
          Navigator.pop(context);
        } else if (responseJSON["result"] == true) {
          ToastComponent.showDialog("🎉 Ödeme başarılı! Siparişiniz oluşturuldu.");
          _navigateToSuccessPage();
        }
      } catch (e) {
        // JSON parse edilemezse, HTML response olarak kabul et
        print('JSON parse failed, treating as HTML response: $e');
        print('Response content: $data');
        
        // HTML response'da "Ödeme Başarılı" veya "Payment successful" arıyoruz
        String responseText = data.toString().toLowerCase();
        if (responseText.contains('ödeme başarılı') || 
            responseText.contains('payment successful') ||
            responseText.contains('başarılı')) {
          ToastComponent.showDialog("🎉 Ödeme başarılı! Siparişiniz oluşturuldu.");
          _navigateToSuccessPage();
        } else {
          ToastComponent.showDialog("Ödeme durumu belirsiz. Lütfen kontrol edin.");
          Navigator.pop(context);
        }
      }
    });
  }

  void _navigateToSuccessPage() {
    if (widget.payment_type == "cart_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderList(from_checkout: true),
        ),
      );
    } else if (widget.payment_type == "order_re_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderList(from_checkout: true),
        ),
      );
    } else if (widget.payment_type == "wallet_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Wallet(from_recharge: true),
        ),
      );
    } else if (widget.payment_type == "customer_package_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Profile(),
        ),
      );
    }
  }

  @override
  void dispose() {
    // WebView'ı temizle
    try {
      _webViewController.clearCache();
    } catch (e) {
      print('WebView dispose error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody(),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.back, color: MyTheme.dark_font_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        "PayTR Payment",
        style: TextStyle(fontSize: 16, color: MyTheme.dark_font_grey),
      ),
      elevation: 0.0,
    );
  }

  buildBody() {
    if (_order_init == false && widget.payment_type == "cart_payment") {
      return Container(
        child: Center(
          child: Text(AppLocalizations.of(context)!.creating_order),
        ),
      );
    } else if (_initial_url_fetched == false) {
      return Container(
        child: Center(
          child: Text("PayTR URL alınıyor..."),
        ),
      );
    } else {
      return Container(
        child: WebViewWidget(
          controller: _webViewController,
        ),
      );
    }
  }
}
