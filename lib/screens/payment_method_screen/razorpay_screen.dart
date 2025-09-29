import 'dart:convert';

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

import '../../helpers/system_config.dart';
import '../profile.dart';

class RazorpayScreen extends StatefulWidget {
  double? amount;
  String payment_type;
  String? payment_method_key;
  int? orderId;
  var package_id;
  RazorpayScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.payment_type = "",
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  _RazorpayScreenState createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  int? _combined_order_id = 0;
  bool _order_init = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();

    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      razorpay();
    }
  }

  razorpay() {
    String initialUrl =
        "${AppConfig.BASE_URL}/razorpay/pay-with-razorpay?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id${widget.orderId}";

    // print(initial_url);

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            // print("page");
            // print(page);
            if (page.contains("/razorpay/success")) {
              print(page.toString());
              getData();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(initialUrl),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
          "Authorization": "Bearer ${access_token.$}",
          "Currency-Code": SystemConfig.systemCurrency!.code!,
          "Currency-Exchange-Rate":
              SystemConfig.systemCurrency!.exchangeRate.toString(),
        },
      );
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

    razorpay();
    // print("-----------");

    // print(_combined_order_id);
    // print(user_id.$);
    // print(widget.amount);
    // print(widget.payment_method_key);
    // print(widget.payment_type);
    // print("-----------");
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

  void getData() {
    String? paymentDetails = '';
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);
          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }

          // print('responseJSON');
          // print(responseJSON);
          if (responseJSON["result"] == false) {
            ToastComponent.showDialog(responseJSON["message"]);

            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            paymentDetails = responseJSON['payment_details'];
            onPaymentSuccess(paymentDetails);
          }
        });
  }

  onPaymentSuccess(paymentDetails) async {
    var razorpayPaymentSuccessResponse = await PaymentRepository()
        .getRazorpayPaymentSuccessResponse(
          widget.payment_type,
          widget.amount,
          _combined_order_id,
          paymentDetails,
        );

    if (razorpayPaymentSuccessResponse.result == false) {
      ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);
      Navigator.pop(context);
      return;
    }
    // print(razorpayPaymentSuccessResponse);
    // print(razorpayPaymentSuccessResponse.message);

    ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);

    if (widget.payment_type == "cart_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderList(from_checkout: true);
          },
        ),
      );
    } else if (widget.payment_type == "wallet_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Wallet(from_recharge: true);
          },
        ),
      );
    } else if (widget.payment_type == "order_re_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderList(from_checkout: true);
          },
        ),
      );
    } else if (widget.payment_type == "customer_package_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Profile();
          },
        ),
      );
    }
  }

  buildBody() {
    if (_order_init == false &&
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
        AppLocalizations.of(context)!.pay_with_razorpay,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
