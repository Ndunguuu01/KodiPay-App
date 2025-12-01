import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maintenance_request.dart';
import '../utils/constants.dart';

class MaintenanceService {
  Future<List<MaintenanceRequest>> getRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/maintenance?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MaintenanceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load maintenance requests');
    }
  }

  Future<Map<String, dynamic>> createRequest(MaintenanceRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      return {'success': false, 'message': 'No access token found'};
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/maintenance'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create request'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<MaintenanceRequest>> getLandlordRequests(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/maintenance/landlord/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MaintenanceRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load maintenance requests');
    }
  }
}
