import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<Map<String, dynamic>> postAd(MarketplaceAd ad) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      return {'success': false, 'message': 'No access token found'};
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ads'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode(ad.toJson()),
      );

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
}
