import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';
import '../utils/constants.dart';

class PaymentService {
  Future<List<Payment>> getPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');
    final role = prefs.getString('userRole');

    if (token == null) {
      throw Exception('No access token found');
    }

    String url = '${AppConstants.baseUrl}/payments';
    if (role == 'tenant') {
      url += '?tenant_id=$userId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payments');
    }
  }

  Future<Map<String, dynamic>> createPayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      return {'success': false, 'message': 'No access token found'};
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payments'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode(payment.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Payment failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
