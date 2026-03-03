import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class PaymentService {
  Future<List<Payment>> getPayments() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('No access token found');

    // Server now scopes by role — no need to add ?tenant_id= client-side
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/payments'),
      headers: {'Content-Type': 'application/json', 'x-access-token': token},
    );

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      final List<dynamic> data = body is Map ? (body['data'] ?? []) : body;
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payments');
    }
  }

  Future<Map<String, dynamic>> createPayment(Payment payment) async {
    final token = await SecureStorage.getToken();
    if (token == null)
      return {'success': false, 'message': 'No access token found'};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payments'),
        headers: {'Content-Type': 'application/json', 'x-access-token': token},
        body: jsonEncode(payment.toJson()),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Payment failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }
}
