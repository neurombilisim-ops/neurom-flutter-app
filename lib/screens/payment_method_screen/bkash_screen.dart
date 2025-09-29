import 'dart:convert';

import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
import 'package:neurom_bilisim_store/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_config.dart';
import '../../helpers/shared_value_helper.dart';
import '../profile.dart';

class BkashScreen extends StatefulWidget {
  double? amount;
  String payment_type;
  String? payment_method_key;
  var package_id;
  int? orderId;
  BkashScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.payment_type = "",
    this.payment_method_key = "",
    this.package_id = "0",
  });

  @override
  _BkashScreenState createState() => _BkashScreenState();
}

class _BkashScreenState extends State<BkashScreen> {
  int? _combined_order_id = 0;
  bool _order_init = false;
  String? _initial_url = "";
  bool _initial_url_fetched = false;

  final String? _token = "";
  bool showLoading = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.payment_type == "cart_payment") {
      createOrder();
    }

    if (widget.payment_type != "cart_payment") {
      // on cart payment need proper order id
      bkash();
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

    // getSetInitialUrl();
    bkash();
  }

  // getSetInitialUrl() async {
  //   // var bkashUrlResponse = await PaymentRepository().getBkashBeginResponse(
  //   //     widget.payment_type,
  //   //     _combined_order_id,
  //   //     widget.package_id,
  //   //     widget.amount,
  //   //     widget.orderId!);
  //
  //   // _initial_url =
  //   //     "${AppConfig.BASE_URL}/bkash/begin?payment_type=${widget.payment_type}&combined_order_id=${_combined_order_id}&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}";
  //   //
  //
  //   _initial_url =
  //       ("${AppConfig.BASE_URL}/bkash/begin?payment_type=${widget.payment_type}&combined_order_id=${_combined_order_id}&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}");
  //
  //   // if (bkashUrlResponse.result == false) {
  //   //   ToastComponent.showDialog(bkashUrlResponse.message!,
  //   //       gravity: Toast.center, duration: Toast.lengthLong);
  //   //   Navigator.of(context).pop();
  //   //   return;
  //   // }
  //   // _token = bkashUrlResponse.token;
  //   //
  //   // _initial_url = bkashUrlResponse.url;
  //   _initial_url_fetched = true;
  //
  //   setState(() {});
  //   bkash();
  //
  //   print(_initial_url);
  //   print(_initial_url_fetched);
  // }

  bkash() {
    _initial_url =
        ("${AppConfig.BASE_URL}/bkash/begin?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}");

    _initial_url_fetched = true;
    setState(() {});

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/bkash/api/callback")) {
              getData();
            }
            // else if (page.contains("/bkash/api/fail")) {
            //   ToastComponent.showDialog("Payment cancelled",
            //       gravity: Toast.center, duration: Toast.lengthLong);
            //   Navigator.of(context).pop();
            //   return;
            // }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_initial_url!),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
          "Authorization": "Bearer ${access_token.$}",
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  void getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);
          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }
          // response result
          // if response result false then  pop
          if (responseJSON["result"] == false) {
            ToastComponent.showDialog(responseJSON["message"]);
            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            ToastComponent.showDialog(responseJSON["message"]);

            if (widget.payment_type == "cart_payment") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(from_checkout: true);
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
            } else if (widget.payment_type == "wallet_payment") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Wallet(from_recharge: true);
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
        });
  }
  // void getData() {
  //   String? payment_details = '';
  //   _webViewController
  //       .runJavaScriptReturningResult("document.body.innerText")
  //       .then((data) {
  //     var responseJSON = jsonDecode(data as String);
  //
  //     print("responseJSON");
  //     print(responseJSON);
  //
  //     if (responseJSON.runtimeType == String) {
  //       responseJSON = jsonDecode(responseJSON);
  //     }
  //     print(data);
  //     if (responseJSON["result"] == false) {
  //       ToastComponent.showDialog(responseJSON["message"],
  //           duration: Toast.lengthLong, gravity: Toast.center);
  //       Navigator.pop(context);
  //     } else if (responseJSON["result"] == true) {
  //       payment_details = responseJSON['payment_details'];
  //       onPaymentSuccess(responseJSON);
  //     }
  //   });
  // }

  // onPaymentSuccess(payment_details) async {
  //   showLoading = true;
  //   setState(() {});
  //
  //   var bkashPaymentProcessResponse =
  //       await PaymentRepository().getBkashPaymentProcessResponse(
  //     amount: widget.amount,
  //     token: _token,
  //     payment_type: widget.payment_type,
  //     combined_order_id: _combined_order_id,
  //     package_id: widget.package_id,
  //     payment_id: payment_details['paymentID'],
  //   );
  //
  //   if (bkashPaymentProcessResponse.result == false) {
  //     ToastComponent.showDialog(bkashPaymentProcessResponse.message!,
  //         duration: Toast.lengthLong, gravity: Toast.center);
  //     Navigator.pop(context);
  //     return;
  //   }
  //
  //   ToastComponent.showDialog(bkashPaymentProcessResponse.message!,
  //       duration: Toast.lengthLong, gravity: Toast.center);
  //   if (widget.payment_type == "cart_payment") {
  //     Navigator.push(context, MaterialPageRoute(builder: (context) {
  //       return OrderList(from_checkout: true);
  //     }));
  //   } else if (widget.payment_type == "order_re_payment") {
  //     Navigator.push(context, MaterialPageRoute(builder: (context) {
  //       return OrderList(from_checkout: true);
  //     }));
  //   } else if (widget.payment_type == "wallet_payment") {
  //     Navigator.push(context, MaterialPageRoute(builder: (context) {
  //       return Wallet(from_recharge: true);
  //     }));
  //   } else if (widget.payment_type == "customer_package_payment") {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
  //       return Profile();
  //     }));
  //   }
  // }

  buildBody() {
    if (_order_init == false &&
        _combined_order_id == 0 &&
        widget.payment_type == "cart_payment") {
      return Container(
        child: Center(
          child: Text(AppLocalizations.of(context)!.creating_order),
        ),
      );
    } else if (_initial_url_fetched == false) {
      return Container(
        child: Center(
          child: Text(AppLocalizations.of(context)!.fetching_bkash_url),
        ),
      );
    } else {
      return SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: WebViewWidget(controller: _webViewController),
        ),
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
        AppLocalizations.of(context)!.pay_with_bkash,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
