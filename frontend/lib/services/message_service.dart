import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../utils/constants.dart';

class MessageService {
  Future<List<Message>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getInt('userId');

    if (token == null) {
      throw Exception('No access token found');
    }

    // Fetch messages where user is sender OR receiver
    // Note: The backend endpoint might need adjustment to handle this "inbox" logic perfectly,
    // but for now we pass user_id and assume backend filters relevant messages.
    // We'll use a query param to hint the backend if needed, or rely on backend to use the token's user ID.
    // Based on previous analysis, backend takes user_id and other_user_id. 
    // For a general inbox, we might need a new endpoint or just fetch all for now.
    // Let's assume we want to see all messages involving this user.
    
    // Since the backend findAll expects user_id and other_user_id for a chat, 
    // or group_id. We might need to adjust this. 
    // For now, let's try to fetch all messages for the logged-in user.
    // If the backend doesn't support "all my messages", we might only get empty list or error.
    // Let's try passing just user_id as sender_id to see sent messages, or we might need to update backend.
    // Wait, let's look at backend again.
    // exports.findAll = (req, res) => { const { user_id, other_user_id, group_id } = req.query; ... }
    // It seems designed for a specific chat thread.
    // We might need to implement a "get all my conversations" or "get all messages" endpoint in backend later.
    // For this step, let's implement the service to fetch messages between current user and "someone".
    // Actually, let's just try to fetch all messages where user is involved if we can.
    // If not, we might need to just show a "Compose" feature mostly.
    
    // Let's implement a simple fetch that tries to get messages.
    // We will assume for now we are fetching messages for a specific context or just all.
    // Let's pass user_id as a param.
    
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/messages?user_id=$userId'), 
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      return {'success': false, 'message': 'No access token found'};
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode(message.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
