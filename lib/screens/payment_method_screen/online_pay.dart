import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
import 'package:neurom_bilisim_store/screens/package/packages.dart';
import 'package:neurom_bilisim_store/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnlinePay extends StatefulWidget {
  String? title;
  double? amount;
  String payment_type;
  String? payment_method_key;
  var package_id;
  int? orderId;
  OnlinePay({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.title = "Pay With Instamojo",
    this.payment_type = "",
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  _OnlinePayState createState() => _OnlinePayState();
}

class _OnlinePayState extends State<OnlinePay> {
  int? _combined_order_id = 0;
  bool _initial_url_fetched = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      pay(
        Uri.parse(
          "${AppConfig.BASE_URL}/online-pay/init?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&wallet_amount=${widget.amount}&payment_option=${widget.payment_method_key}&order_id=${widget.orderId}",
        ),
      );
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
    pay(
      Uri.parse(
        "${AppConfig.BASE_URL}/online-pay/init?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&wallet_amount=${widget.amount}&payment_option=${widget.payment_method_key}",
      ),
    );
  }

  pay(url) {
    print(url);
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            print(page);
            if (page.contains("/online-pay/done")) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdatePackage(goHome: true),
                  ),
                );
              }
            }
            if (page.contains("/online-pay/failed")) {
              getData();
              Navigator.pop(context);
            }
          },
        ),
      )
      ..loadRequest(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
        },
      );
    _initial_url_fetched = true;
    setState(() {});
  }

  void getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);

          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }
          // ToastContext().init(context);/**/
          /// todo:: show message
          ToastComponent.showDialog(responseJSON["message"]);
        });
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

  buildBody() {
    if (_initial_url_fetched == false &&
        _combined_order_id == 0 &&
        widget.payment_type == "cart_payment") {
      return Container(
        child: Center(
          child: Text(AppLocalizations.of(context)!.creating_order),
        ),
      );
    } else {
      return SizedBox.expand(
        child: Container(child: WebViewWidget(controller: _webViewController)),
      );
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        widget.title!,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
