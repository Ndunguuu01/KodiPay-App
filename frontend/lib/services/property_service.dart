import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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

  Future<Map<String, dynamic>> createProperty(Property property, {int? roomsPerFloor, double? defaultRent, XFile? imageFile}) async {
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

      final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/properties'));
      request.headers.addAll({
        'x-access-token': token ?? '',
      });

      // Add fields
      request.fields['name'] = property.name;
      request.fields['location'] = property.location;
      request.fields['floors_count'] = property.floorsCount.toString();
      request.fields['landlord_id'] = userId.toString();
      if (roomsPerFloor != null) request.fields['rooms_per_floor'] = roomsPerFloor.toString();
      if (defaultRent != null) request.fields['default_rent'] = defaultRent.toString();

      // Add file
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image', 
          bytes,
          filename: imageFile.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
