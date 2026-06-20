import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

abstract class PaymentGateway {
  Future<bool> process({required double amount, required String currency, required Map<String, dynamic> userData});
}

class StripeGateway implements PaymentGateway {
  // IMPORTANT: In a real app, the Secret Key MUST be on the server.
  // This is for demonstration purposes in a portfolio project.
  static const String _secretKey = "sk_test_YOUR_STRIPE_SECRET_KEY"; 
  static const String publishableKey = "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY";

  @override
  Future<bool> process({required double amount, required String currency, required Map<String, dynamic> userData}) async {
    try {
      // 1. Create Payment Intent on the server (simulated here)
      final intentData = await _createPaymentIntent((amount * 100).toInt().toString(), currency);
      
      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intentData['client_secret'],
          merchantDisplayName: 'Stockify',
          customerId: userData['customerId'],
          customerEphemeralKeySecret: userData['ephemeralKey'],
          style: ThemeMode.light,
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();
      
      return true;
    } catch (e) {
      debugPrint("Stripe Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(String amount, String currency) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card',
      },
    );
    return jsonDecode(response.body);
  }
}

class PaymobGateway implements PaymentGateway {
  static const String apiKey = "YOUR_PAYMOB_API_KEY";
  static const String integrationId = "YOUR_INTEGRATION_ID";

  @override
  Future<bool> process({required double amount, required String currency, required Map<String, dynamic> userData}) async {
    try {
      // 1. Authentication Request
      final token = await _getAuthToken();
      
      // 2. Order Registration
      final orderId = await _registerOrder(token, (amount * 100).toInt().toString());
      
      // 3. Payment Key Request
      final paymentKey = await _getPaymentKey(token, orderId, (amount * 100).toInt().toString(), currency, userData);
      
      // 4. In a real app, you would navigate to a WebView with Paymob's iframe
      // or use their SDK. For this portfolio, we simulate the flow.
      debugPrint("Paymob Payment Key: $paymentKey");
      
      // Simulate success for demo
      return true; 
    } catch (e) {
      debugPrint("Paymob Error: $e");
      return false;
    }
  }

  Future<String> _getAuthToken() async {
    final response = await http.post(
      Uri.parse('https://pakistan.paymob.com/api/auth/tokens'), // Use correct regional URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'api_key': apiKey}),
    );
    return jsonDecode(response.body)['token'];
  }

  Future<String> _registerOrder(String token, String amount) async {
    final response = await http.post(
      Uri.parse('https://pakistan.paymob.com/api/ecommerce/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': token,
        'delivery_needed': 'false',
        'amount_cents': amount,
        'currency': 'EGP',
        'items': [],
      }),
    );
    return jsonDecode(response.body)['id'].toString();
  }

  Future<String> _getPaymentKey(String token, String orderId, String amount, String currency, Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('https://pakistan.paymob.com/api/acceptance/payment_keys'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'auth_token': token,
        'amount_cents': amount,
        'expiration': 3600,
        'order_id': orderId,
        'billing_data': {
          'apartment': '803',
          'email': userData['email'] ?? 'test@example.com',
          'floor': '42',
          'first_name': userData['firstName'] ?? 'User',
          'street': 'Ethan Hunt',
          'building': '8028',
          'phone_number': userData['phone'] ?? '+201111111111',
          'shipping_method': 'PKG',
          'postal_code': '01898',
          'city': 'Cairo',
          'country': 'EG',
          'last_name': userData['lastName'] ?? 'User',
          'state': 'Cairo',
        },
        'currency': currency,
        'integration_id': integrationId,
      }),
    );
    return jsonDecode(response.body)['token'];
  }
}

class CashGateway implements PaymentGateway {
  @override
  Future<bool> process({required double amount, required String currency, required Map<String, dynamic> userData}) async {
    return true;
  }
}

class PaymentFactory {
  static PaymentGateway getGateway(String method) {
    switch (method) {
      case 'Stripe':
        return StripeGateway();
      case 'Paymob':
        return PaymobGateway();
      case 'Cash':
        return CashGateway();
      default:
        return CashGateway();
    }
  }
}
