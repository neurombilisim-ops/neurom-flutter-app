// import 'dart:convert';
//
// import 'package:neurom_bilisim_store/app_config.dart';
// import 'package:neurom_bilisim_store/custom/toast_component.dart';
// import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
// import 'package:neurom_bilisim_store/my_theme.dart';
// import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
// import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
// import 'package:neurom_bilisim_store/screens/profile.dart';
// import 'package:neurom_bilisim_store/screens/wallet.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// import '../../helpers/system_config.dart';
//
// class PhonepayScreen extends StatefulWidget {
//   double? amount;
//   String payment_type;
//   String? payment_method_key;
//   String package_id;
//   int? orderId;
//   PhonepayScreen({
//     super.key,
//     this.amount = 0.00,
//     this.orderId = 0,
//     this.payment_type = "",
//     this.payment_method_key = "",
//     this.package_id = "0",
//   });
//
//   @override
//   _PhonepayScreenState createState() => _PhonepayScreenState();
// }
//
// class _PhonepayScreenState extends State<PhonepayScreen> {
//   int? _combined_order_id = 0;
//   bool _order_init = false;
//
//   final WebViewController _webViewController = WebViewController();
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     if (widget.payment_type == "cart_payment") {
//       createOrder();
//     } else {
//       phonepay();
//     }
//   }
//
//   phonepay() {
//     String initial_url =
//         "${AppConfig.BASE_URL}/phonepe/payment/pay?payment_type=${widget.payment_type}&combined_order_id=$_combined_order_id&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}";
//
//     print(initial_url);
//
//     _webViewController
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onWebResourceError: (error) {},
//           onPageFinished: (page) {
//             if (page.contains("/phonepe/redirecturl")) {
//               getData();
//             }
//           },
//         ),
//       )
//       ..loadRequest(
//         Uri.parse(initial_url),
//         headers: {
//           "Content-Type": "application/json",
//           "App-Language": app_language.$!,
//           "Accept": "application/json",
//           "System-Key": AppConfig.system_key,
//           "Authorization": "Bearer ${access_token.$}",
//           "Currency-Code": SystemConfig.systemCurrency!.code!,
//           "Currency-Exchange-Rate":
//               SystemConfig.systemCurrency!.exchangeRate.toString(),
//         },
//       );
//   }
//
//   createOrder() async {
//     var orderCreateResponse = await PaymentRepository().getOrderCreateResponse(
//       widget.payment_method_key,
//     );
//
//     if (orderCreateResponse.result == false) {
//       ToastComponent.showDialog(orderCreateResponse.message);
//       Navigator.of(context).pop();
//       return;
//     }
//
//     _combined_order_id = orderCreateResponse.combined_order_id;
//     _order_init = true;
//     setState(() {});
//     phonepay();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection:
//           app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: buildAppBar(context),
//         body: buildBody(),
//       ),
//     );
//   }
//
//   void getData() {
//     _webViewController
//         .runJavaScriptReturningResult("document.body.innerText")
//         .then((data) {
//           var responseJSON = jsonDecode(data as String);
//           if (responseJSON.runtimeType == String) {
//             responseJSON = jsonDecode(responseJSON);
//           }
//           if (responseJSON["result"] == false) {
//             ToastComponent.showDialog(responseJSON["message"]);
//
//             Navigator.pop(context);
//           } else if (responseJSON["result"] == true) {
//             ToastComponent.showDialog(responseJSON["message"]);
//
//             if (widget.payment_type == "cart_payment") {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return OrderList(from_checkout: true);
//                   },
//                 ),
//               );
//             } else if (widget.payment_type == "order_re_payment") {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return OrderList(from_checkout: true);
//                   },
//                 ),
//               );
//             } else if (widget.payment_type == "wallet_payment") {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return Wallet(from_recharge: true);
//                   },
//                 ),
//               );
//             } else if (widget.payment_type == "customer_package_payment") {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return Profile();
//                   },
//                 ),
//               );
//             }
//           }
//         });
//   }
//
//   buildBody() {
//     if (_order_init == false &&
//         _combined_order_id == 0 &&
//         widget.payment_type == "cart_payment") {
//       return Container(
//         child: Center(
//           child: Text(AppLocalizations.of(context)!.creating_order),
//         ),
//       );
//     } else {
//       return SingleChildScrollView(
//         child: SizedBox(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           child: WebViewWidget(controller: _webViewController),
//         ),
//       );
//     }
//   }
//
//   AppBar buildAppBar(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       centerTitle: true,
//       leading: Builder(
//         builder:
//             (context) => IconButton(
//               icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//       ),
//       title: Text(
//         AppLocalizations.of(context)!.pay_with_phonepay,
//         style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
//       ),
//       elevation: 0.0,
//       titleSpacing: 0,
//     );
//   }
// }
