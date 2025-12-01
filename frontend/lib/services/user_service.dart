import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class UserService {
  Future<List<Map<String, dynamic>>> searchTenants(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/tenants?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load tenants');
      }
    } catch (e) {
      throw Exception('Error searching tenants: $e');
    }
  }

  Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
}
