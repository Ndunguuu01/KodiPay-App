import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/maintenance_request.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class MaintenanceService {
  Future<List<MaintenanceRequest>> getRequests() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('No access token found');

    // Server auto-scopes by role — no ?user_id= needed
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/maintenance'),
      headers: {'Content-Type': 'application/json', 'x-access-token': token},
    );

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      final List<dynamic> data = body is Map ? (body['data'] ?? []) : body;
      return data.map((json) => MaintenanceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load maintenance requests');
    }
  }

  Future<Map<String, dynamic>> createRequest(MaintenanceRequest request) async {
    final token = await SecureStorage.getToken();
    if (token == null)
      return {'success': false, 'message': 'No access token found'};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/maintenance'),
        headers: {'Content-Type': 'application/json', 'x-access-token': token},
        body: jsonEncode(request.toJson()),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create request'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<List<MaintenanceRequest>> getLandlordRequests(int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('No access token found');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/maintenance/landlord/$userId'),
      headers: {'Content-Type': 'application/json', 'x-access-token': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MaintenanceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load maintenance requests');
    }
  }
}
