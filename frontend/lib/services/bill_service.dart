import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class BillService {
  Future<Map<String, dynamic>> createBill(Bill bill) async {
    final token = await SecureStorage.getToken();
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/bills'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode(bill.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<List<Bill>> getBillsByTenant(int tenantId) async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/bills/tenant/$tenantId'),
      headers: {'x-access-token': token ?? ''},
    );
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      final List<dynamic> data = body is Map ? (body['data'] ?? []) : body;
      return data.map((json) => Bill.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bills');
    }
  }

  Future<List<Bill>> getBillsByUnit(int unitId) async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/bills/unit/$unitId'),
      headers: {'x-access-token': token ?? ''},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Bill.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bills');
    }
  }

  Future<bool> markAsPaid(int billId) async {
    final token = await SecureStorage.getToken();
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/bills/$billId/pay'),
      headers: {'x-access-token': token ?? ''},
    );
    return response.statusCode == 200;
  }
}
