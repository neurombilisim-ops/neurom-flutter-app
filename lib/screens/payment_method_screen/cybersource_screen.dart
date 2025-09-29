// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:neurom_bilisim_store/app_config.dart';
// import 'package:neurom_bilisim_store/custom/toast_component.dart';
// import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
// import 'package:neurom_bilisim_store/my_theme.dart';
// import 'package:neurom_bilisim_store/repositories/payment_repository.dart';
// import 'package:neurom_bilisim_store/screens/orders/order_list.dart';
// import 'package:neurom_bilisim_store/screens/wallet.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../../custom/lang_text.dart';
// import '../../helpers/main_helpers.dart';
// import '../profile.dart';

// class CybersourceScreen extends StatefulWidget {
//   final double? amount;
//   final String payment_type;
//   final String? payment_method_key;
//   final dynamic package_id;
//   final int? orderId;

//   const CybersourceScreen({
//     Key? key,
//     this.amount = 0.00,
//     this.orderId = 0,
//     required this.payment_type,
//     this.package_id = "0",
//     this.payment_method_key = "",
//   }) : super(key: key);

//   @override
//   State<CybersourceScreen> createState() => _CybersourceScreenState();
// }

// class _CybersourceScreenState extends State<CybersourceScreen> {
//   int? _combined_order_id = 0;
//   bool _order_init = false;
//   bool _isLoading = true;
//   bool _paymentCompleted = false;
//   String? _errorMessage;
//   String? _currentUrl;

//   late WebViewController _webViewController;
//   final Completer<WebViewController> _controllerCompleter =
//       Completer<WebViewController>();

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebViewController();

//     if (widget.payment_type == "cart_payment") {
//       createOrder();
//     } else {
//       _order_init = true;
//       initiateCybersourcePayment();
//     }
//   }

//   void _initializeWebViewController() {
//     _webViewController = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             if (kDebugMode) {
//               print('WebView loading: $progress%');
//             }
//           },
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//               _currentUrl = url;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//               _currentUrl = url;
//             });

//             if (url.contains('${AppConfig.BASE_URL}/payment/success') ||
//                 url.contains('/cyber-source/payment/callback') ||
//                 url.contains('/payment/complete')) {
//               _handlePaymentSuccess();
//             } else if (url.contains('/payment/failure') ||
//                 url.contains('/payment/error')) {
//               _handlePaymentFailure();
//             }
//           },
//           onWebResourceError: (WebResourceError error) {
//             setState(() {
//               _errorMessage = 'Payment failed: ${error.description}';
//               _isLoading = false;
//             });
//             if (kDebugMode) {
//               print('WebView error: ${error.description}');
//             }
//           },
//           onUrlChange: (UrlChange change) {
//             if (kDebugMode) {
//               print('URL changed to: ${change.url}');
//             }
//             setState(() {
//               _currentUrl = change.url;
//             });
//           },
//         ),
//       )
//       ..addJavaScriptChannel('PaymentHandler',
//           onMessageReceived: (JavaScriptMessage message) {
//         if (message.message == 'payment_success') {
//           _handlePaymentSuccess();
//         } else if (message.message == 'payment_failure') {
//           _handlePaymentFailure();
//         }
//       });

//     _controllerCompleter.complete(_webViewController);
//   }

//   void createOrder() async {
//     try {
//       final orderCreateResponse = await PaymentRepository()
//           .getOrderCreateResponse(widget.payment_method_key);

//       if (orderCreateResponse.result == false) {
//         _showErrorAndClose(orderCreateResponse.message);
//         return;
//       }

//       setState(() {
//         _combined_order_id = orderCreateResponse.combined_order_id;
//         _order_init = true;
//       });

//       initiateCybersourcePayment();
//     } catch (e) {
//       _showErrorAndClose('Failed to create order: $e');
//     }
//   }

//   Future<void> initiateCybersourcePayment() async {
//     try {
//       final postData = _buildPaymentPostData();
//       final response = await http.post(
//         Uri.parse("${AppConfig.BASE_URL}/cyber-source/payment/pay"),
//         headers: commonHeader,
//         body: json.encode(postData),
//       );

//       if (response.statusCode == 200) {
//         await _webViewController.loadHtmlString(response.body);

//         await _webViewController.runJavaScript('''
//           // Auto-submit the form if it exists
//           if (document.getElementById('payment_form')) {
//             document.getElementById('payment_form').submit();
//           }

//           // Listen for payment completion
//           window.addEventListener('message', function(event) {
//             if (event.data.type === 'payment_completed') {
//               PaymentHandler.postMessage('payment_success');
//             } else if (event.data.type === 'payment_failed') {
//               PaymentHandler.postMessage('payment_failure');
//             }
//           });
//         ''');
//       } else {
//         _showErrorAndClose(
//             'Failed to initiate payment: ${response.statusCode}');
//       }
//     } catch (e) {
//       _showErrorAndClose('Payment initialization error: $e');
//     }
//   }

//   Map<String, dynamic> _buildPaymentPostData() {
//     final postData = {
//       "payment_type": widget.payment_type,
//       "user_id": user_id.$,
//       "amount": widget.amount,
//     };

//     if (widget.payment_type == 'cart_payment') {
//       postData['combined_order_id'] = _combined_order_id;
//     } else if (widget.payment_type == 'wallet_payment') {
//       postData['payment_method'] = "cybersource";
//     } else if (widget.payment_type == 'order_re_payment') {
//       postData['order_id'] = widget.orderId;
//     } else if (widget.payment_type == 'customer_package_payment') {
//       postData['package_id'] = widget.package_id;
//     }

//     return postData;
//   }

//   void _handlePaymentSuccess() {
//     if (_paymentCompleted) return;

//     setState(() {
//       _paymentCompleted = true;
//       _isLoading = false;
//     });

//     ToastComponent.showDialog("Payment completed successfully!");
//     _navigateAfterPayment();
//   }

//   void _handlePaymentFailure() {
//     setState(() {
//       _errorMessage = "Payment failed. Please try again.";
//       _isLoading = false;
//     });
//   }

//   void _navigateAfterPayment() {
//     Widget targetScreen;

//     if (widget.payment_type == "cart_payment" ||
//         widget.payment_type == "order_re_payment") {
//       targetScreen = OrderList(from_checkout: true);
//     } else if (widget.payment_type == "wallet_payment") {
//       targetScreen = Wallet(from_recharge: true);
//     } else if (widget.payment_type == "customer_package_payment") {
//       targetScreen = Profile();
//     } else {
//       targetScreen = Profile();
//     }

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => targetScreen),
//       (Route<dynamic> route) => false,
//     );
//   }

//   void _showErrorAndClose(String message) {
//     ToastComponent.showDialog(message);
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection:
//           app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: buildAppBar(context),
//         body: _buildPaymentView(),
//       ),
//     );
//   }

//   Widget _buildPaymentView() {
//     if (_errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error, color: Colors.red, size: 48),
//             SizedBox(height: 16),
//             Text(
//               _errorMessage!,
//               style: TextStyle(color: Colors.red, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Go Back'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (!_order_init && widget.payment_type == "cart_payment") {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(LangText(context).local.creating_order),
//           ],
//         ),
//       );
//     }

//     return Stack(
//       children: [
//         WebViewWidget(controller: _webViewController),
//         if (_isLoading)
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text(
//                   _paymentCompleted
//                       ? "Processing payment..."
//                       : "Loading payment gateway...",
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   AppBar buildAppBar(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       centerTitle: true,
//       leading: IconButton(
//         icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
//         onPressed: () {
//           if (!_paymentCompleted) {
//             showDialog(
//               context: context,
//               builder: (context) => AlertDialog(
//                 title: Text("Cancel Payment?"),
//                 content: Text("Are you sure you want to cancel this payment?"),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: Text("No"),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       Navigator.of(context).pop();
//                     },
//                     child: Text("Yes"),
//                   ),
//                 ],
//               ),
//             );
//           } else {
//             Navigator.of(context).pop();
//           }
//         },
//       ),
//       title: Text(
//         "Pay with CyberSource",
//         style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
//       ),
//       elevation: 0.0,
//       titleSpacing: 0,
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import 'package:webview_flutter/webview_flutter.dart';
import '../../custom/lang_text.dart';
import '../../helpers/main_helpers.dart';
import '../profile.dart';

class CybersourceScreen extends StatefulWidget {
  final double? amount;
  final String payment_type;
  final String? payment_method_key;
  final dynamic package_id;
  final int? orderId;

  const CybersourceScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    required this.payment_type,
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  State<CybersourceScreen> createState() => _CybersourceScreenState();
}

class _CybersourceScreenState extends State<CybersourceScreen> {
  int? _combined_order_id = 0;
  bool _order_init = false;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  String? _errorMessage;
  String? _currentUrl;

  late WebViewController _webViewController;
  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();

    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      _order_init = true;
      initiateCybersourcePayment();
    }
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) {
              print('WebView loading: $progress%');
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });

            if (url.contains('${AppConfig.BASE_URL}/payment/success') ||
                url.contains(
                    '${AppConfig.BASE_URL}/cyber-source/payment/callback')) {
              _handlePaymentSuccess();
            } else if (url.contains('/payment/failure') ||
                url.contains('/payment/error')) {
              _handlePaymentFailure();
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Payment failed: ${error.description}';
              _isLoading = false;
            });
            if (kDebugMode) {
              print('WebView error: ${error.description}');
            }
          },
          onUrlChange: (UrlChange change) {
            if (kDebugMode) {
              print('URL changed to: ${change.url}');
            }
            setState(() {
              _currentUrl = change.url;
            });
          },
        ),
      )
      ..addJavaScriptChannel('PaymentHandler',
          onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'payment_success') {
          _handlePaymentSuccess();
        } else if (message.message == 'payment_failure') {
          _handlePaymentFailure();
        }
      });

    _controllerCompleter.complete(_webViewController);
  }

  void createOrder() async {
    try {
      final orderCreateResponse = await PaymentRepository()
          .getOrderCreateResponse(widget.payment_method_key);

      if (orderCreateResponse.result == false) {
        _showErrorAndClose(orderCreateResponse.message);
        return;
      }

      setState(() {
        _combined_order_id = orderCreateResponse.combined_order_id;
        _order_init = true;
      });

      initiateCybersourcePayment();
    } catch (e) {
      _showErrorAndClose('Failed to create order: $e');
    }
  }

  Future<void> initiateCybersourcePayment() async {
    try {
      final postData = _buildPaymentPostData();
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/cyber-source/payment/pay"),
        headers: commonHeader,
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        await _webViewController.loadHtmlString(response.body);
      } else {
        _showErrorAndClose(
            'Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorAndClose('Payment initialization error: $e');
    }
  }

  Map<String, dynamic> _buildPaymentPostData() {
    final postData = {
      "payment_type": widget.payment_type,
      "user_id": user_id.$,
      "amount": widget.amount,
    };

    if (widget.payment_type == 'cart_payment') {
      postData['combined_order_id'] = _combined_order_id;
    } else if (widget.payment_type == 'wallet_payment') {
      postData['payment_method'] = "cybersource";
    } else if (widget.payment_type == 'order_re_payment') {
      postData['order_id'] = widget.orderId;
    } else if (widget.payment_type == 'customer_package_payment') {
      postData['package_id'] = widget.package_id;
    }

    return postData;
  }

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;

    setState(() {
      _paymentCompleted = true;
      _isLoading = false;
    });

    ToastComponent.showDialog("Payment completed successfully!");
    _navigateAfterPayment();
  }

  void _handlePaymentFailure() {
    setState(() {
      _errorMessage = "Payment failed. Please try again.";
      _isLoading = false;
    });
  }

  void _navigateAfterPayment() {
    Widget targetScreen;

    if (widget.payment_type == "cart_payment" ||
        widget.payment_type == "order_re_payment") {
      targetScreen = OrderList(from_checkout: true);
    } else if (widget.payment_type == "wallet_payment") {
      targetScreen = Wallet(from_recharge: true);
    } else if (widget.payment_type == "customer_package_payment") {
      targetScreen = Profile();
    } else {
      targetScreen = Profile(); // Default fallback
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorAndClose(String message) {
    ToastComponent.showDialog(message);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: _buildPaymentView(),
      ),
    );
  }

  Widget _buildPaymentView() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (!_order_init && widget.payment_type == "cart_payment") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(LangText(context).local.creating_order),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  _paymentCompleted
                      ? "Processing payment..."
                      : "Loading payment gateway...",
                ),
              ],
            ),
          ),
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
        onPressed: () {
          if (!_paymentCompleted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Cancel Payment?"),
                content: Text("Are you sure you want to cancel this payment?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        "Pay with CyberSource",
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
