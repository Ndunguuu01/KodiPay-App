import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class DashboardService {
  Future<Map<String, dynamic>> getLandlordInsights() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('No access token found');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/dashboard/landlord'),
      headers: {'x-access-token': token},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load insights');
    }
  }
}
