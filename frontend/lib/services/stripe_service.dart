import 'dart:convert';
import 'package:flutter/material.dart';
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

  Future<void> makePayment(BuildContext context, double amount, String currency,
      int tenantId, int unitId) async {
    try {
      final paymentIntentData = await createPaymentIntent(amount, currency);

      if (paymentIntentData == null) {
        throw Exception("Failed to create payment intent");
      }

      final clientSecret = paymentIntentData['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KodiPay',
          style: ThemeMode.system,
        ),
      );

      await displayPaymentSheet(context);
      await confirmPayment(context, clientSecret, amount, tenantId, unitId);
    } catch (e) {
      debugPrint('Stripe Payment Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(
      double amount, String currency) async {
    try {
      final token = await AuthService().getToken();
      final url =
          Uri.parse('${AppConstants.baseUrl}/payments/create-payment-intent');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: json.encode({'amount': amount, 'currency': currency}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Backend Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  Future<void> displayPaymentSheet(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!')),
        );
      }
      // Webhooks handle backend notification — no manual call needed here
    } on StripeException catch (e) {
      debugPrint('Stripe Exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Cancelled')),
        );
      }
    } catch (e) {
      debugPrint('Error displaying payment sheet: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> confirmPayment(BuildContext context, String paymentIntentId,
      double amount, int tenantId, int unitId) async {
    try {
      final token = await AuthService().getToken();
      final url = Uri.parse('${AppConstants.baseUrl}/payments/confirm-stripe');
      final piId = paymentIntentId.split('_secret_')[0];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? ''
        },
        body: json.encode({
          'paymentIntentId': piId,
          'amount': amount,
          'tenant_id': tenantId,
          'unit_id': unitId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Payment confirmed on backend');
      } else {
        debugPrint('Failed to confirm payment on backend: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Payment recorded failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error confirming payment: $e');
    }
  }
}
