import 'package:neurom_bilisim_store/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class PaymentService {
  static const String _baseUrl = '${AppConfig.BASE_URL}/cyber-source/payment/pay';

  static Future<Map<String, dynamic>> generatePaymentToken({
    required String cardNumber,
    required String expMonth,
    required String expYear,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate-payment-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'card_number': cardNumber,
        'exp_month': expMonth,
        'exp_year': expYear,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> processPayment({
    required String token,
    required String orderId,
    required double amount,
    required String currency,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/process-payment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'order_id': orderId,
        'amount': amount.toString(),
        'currency': currency,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }
}

class CybersourceWithCard extends StatefulWidget {
  const CybersourceWithCard({super.key});

  @override
  _CybersourceWithCardState createState() => _CybersourceWithCardState();
}

class _CybersourceWithCardState extends State<CybersourceWithCard> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool isLoading = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Added formKey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: SafeArea(
        child: Column(
          children: [
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              onCreditCardWidgetChange: (creditCardBrand) {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: CreditCardForm(
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  onCreditCardModelChange: onCreditCardModelChange,

                  formKey: formKey, // Now using the declared formKey
                  cvvValidationMessage: 'Please input a valid CVV',
                  dateValidationMessage: 'Please input a valid date',
                  numberValidationMessage: 'Please input a valid number',
                  cardHolderValidator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _processPayment,
                    child: Text('PAY'),
                  ),
          ],
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  Future<void> _processPayment() async {
    if (!formKey.currentState!.validate()) {
      // Validate form before processing
      return;
    }

    setState(() => isLoading = true);

    try {
      // Extract month and year from expiry date (format: MM/YY)
      final parts = expiryDate.split('/');
      final expMonth = parts[0].trim();
      final expYear = '20${parts[1].trim()}'; // Convert YY to YYYY

      // Generate payment token
      final tokenResponse = await PaymentService.generatePaymentToken(
        cardNumber: cardNumber.replaceAll(' ', ''),
        expMonth: expMonth,
        expYear: expYear,
      );

      // Process payment with token
      final paymentResponse = await PaymentService.processPayment(
        token: tokenResponse['token'],
        orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        amount: 100.0, // Your amount
        currency: 'USD',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
      );

      if (paymentResponse['status'] == 'AUTHORIZED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment failed: ${paymentResponse['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
