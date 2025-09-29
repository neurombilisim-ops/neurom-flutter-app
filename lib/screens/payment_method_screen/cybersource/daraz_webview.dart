// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// class WebViewPage extends StatefulWidget {
//   const WebViewPage({super.key});

//   @override
//   State<WebViewPage> createState() => _WebViewPageState();
// }

// class _WebViewPageState extends State<WebViewPage> {
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..loadRequest(Uri.parse('https://www.daraz.com.bd/'));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Daraz')),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CyberSourcePaymentPage extends StatefulWidget {
  final Map<String, String> paymentData;

  const CyberSourcePaymentPage({super.key, required this.paymentData});

  @override
  State<CyberSourcePaymentPage> createState() => _CyberSourcePaymentPageState();
}

class _CyberSourcePaymentPageState extends State<CyberSourcePaymentPage> {
  late final WebViewController _controller;

  final String paymentUrl = "https://testsecureacceptance.cybersource.com/pay";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(buildHtmlForm());
  }

  String buildHtmlForm() {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head><meta charset="UTF-8"></head>');
    buffer.writeln('<body onload="document.forms[\'payForm\'].submit()">');
    buffer.writeln('<form id="payForm" method="POST" action="$paymentUrl">');

    widget.paymentData.forEach((key, value) {
      buffer.writeln(
          '<input type="hidden" name="${htmlEscape.convert(key)}" value="${htmlEscape.convert(value)}" />');
    });

    buffer.writeln('</form></body></html>');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
