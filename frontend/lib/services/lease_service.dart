import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lease.dart';
import '../utils/constants.dart';

class LeaseService {
  Future<Map<String, dynamic>> createLease(Map<String, dynamic> leaseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/leases'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode(leaseData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Lease created successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create lease'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<Lease>> getLeases(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/leases/tenant/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Lease.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leases');
      }
    } catch (e) {
      throw Exception('Error fetching leases: $e');
    }
  }

  Future<Map<String, dynamic>> signLease(int leaseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/leases/$leaseId/sign'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to sign lease'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<Lease>> getLandlordLeases(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/leases/landlord/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Lease.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leases');
      }
    } catch (e) {
      throw Exception('Error fetching leases: $e');
    }
  }

  Future<Map<String, dynamic>> terminateLease(int leaseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/leases/$leaseId/terminate'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to terminate lease'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
