import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../models/marketplace_ad.dart';
import '../utils/constants.dart';

class MarketplaceService {
  Future<List<MarketplaceAd>> getAds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/ads'),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MarketplaceAd.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ads');
    }
  }

  Future<Map<String, dynamic>> postAd(MarketplaceAd ad, XFile? imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      return {'success': false, 'message': 'No access token found'};
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/ads'));
      request.headers['x-access-token'] = token;

      request.fields['title'] = ad.title;
      if (ad.description != null) request.fields['description'] = ad.description!;
      if (ad.contactInfo != null) request.fields['contact_info'] = ad.contactInfo!;
      request.fields['type'] = ad.type;
      request.fields['user_id'] = ad.userId.toString();

      if (imageFile != null) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to post ad'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> deleteAd(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/ads/$adId'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
