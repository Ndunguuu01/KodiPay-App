import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();

  factory StripeService() {
    return _instance;
  }

  StripeService._internal();

  Future<void> makePayment(BuildContext context, double amount, String currency, int tenantId, int unitId) async {
    try {
      // 1. Create Payment Intent on Backend
      final paymentIntentData = await createPaymentIntent(amount, currency);

      if (paymentIntentData == null) {
        throw Exception("Failed to create payment intent");
      }

      final clientSecret = paymentIntentData['clientSecret'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KodiPay',
          style: ThemeMode.system,
        ),
      );

      // 3. Display Payment Sheet
      await displayPaymentSheet(context);

      // 4. Confirm Payment on Backend
      await confirmPayment(context, clientSecret, amount, tenantId, unitId);

    } catch (e) {
      print('Stripe Payment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(double amount, String currency) async {
    try {
      final token = await AuthService().getToken();
      final url = Uri.parse('${AppConstants.baseUrl}/payments/create-payment-intent');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Backend Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  Future<void> displayPaymentSheet(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );
      
      // TODO: Notify backend of success if needed (Webhooks are better for this)

    } on StripeException catch (e) {
      print('Stripe Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Cancelled')),
      );
    } catch (e) {
      print('Error displaying payment sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> confirmPayment(BuildContext context, String paymentIntentId, double amount, int tenantId, int unitId) async {
    try {
      final token = await AuthService().getToken();
      final url = Uri.parse('${AppConstants.baseUrl}/payments/confirm-stripe');

      // Extract PaymentIntent ID from Client Secret (pi_..._secret_...)
      final piId = paymentIntentId.split('_secret_')[0];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: json.encode({
          'paymentIntentId': piId,
          'amount': amount,
          'tenant_id': tenantId,
          'unit_id': unitId,
        }),
      );

      if (response.statusCode == 200) {
        print('Payment confirmed on backend');
      } else {
        print('Failed to confirm payment on backend: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded failed: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error confirming payment: $e');
    }
  }
}
