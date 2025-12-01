import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';
import '../utils/constants.dart';

class PropertyService {
  Future<Property?> getPropertyById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/properties/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Property.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching property: $e');
    }
  }

  Future<List<Property>> getProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/properties'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      throw Exception('Error fetching properties: $e');
    }
  }

  Future<Map<String, dynamic>> createProperty(Property property, {int? roomsPerFloor, double? defaultRent}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      
      // Robustly retrieve userId, handling both int and String storage
      int? userId;
      try {
        userId = prefs.getInt('userId');
      } catch (e) {
        // If stored as String, try to parse
        final userIdStr = prefs.getString('userId');
        if (userIdStr != null) {
          userId = int.tryParse(userIdStr);
        }
      }

      final body = property.toJson();
      body['landlord_id'] = userId; // Ensure landlord_id is set
      if (roomsPerFloor != null) body['rooms_per_floor'] = roomsPerFloor;
      if (defaultRent != null) body['default_rent'] = defaultRent;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/properties'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Property created successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create property'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
