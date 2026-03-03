import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class MessageService {
  Future<List<Message>> getMessages() async {
    final token = await SecureStorage.getToken();
    final userId = await SecureStorage.getUserId();
    if (token == null) throw Exception('No access token found');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/messages?user_id=$userId'),
      headers: {'Content-Type': 'application/json', 'x-access-token': token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(Message message) async {
    final token = await SecureStorage.getToken();
    if (token == null)
      return {'success': false, 'message': 'No access token found'};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/messages'),
        headers: {'Content-Type': 'application/json', 'x-access-token': token},
        body: jsonEncode(message.toJson()),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }
}
