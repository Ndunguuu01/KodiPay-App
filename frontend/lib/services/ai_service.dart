import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

/// AIService — calls the backend proxy endpoint instead of the Gemini SDK directly.
/// The Gemini API key NEVER leaves the backend server.
/// This file contains NO API keys.
class AIService {
  Future<String> sendMessage(
    String message,
    Map<String, dynamic> context,
  ) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        return 'Please log in to use the AI assistant.';
      }

      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/ai/chat'),
            headers: {
              'Content-Type': 'application/json',
              'x-access-token': token,
            },
            body: jsonEncode({
              'message': message,
              'context': {
                'userName': context['userName'],
                'rentAmount': context['rentAmount'],
                'bills': context['bills'] ?? [],
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "I'm sorry, I couldn't generate a response.";
      } else if (response.statusCode == 401) {
        return 'Session expired. Please log in again.';
      } else if (response.statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      } else {
        return "I'm having trouble connecting. Please try again later.";
      }
    } catch (e) {
      // Never expose raw error to the user
      return "I'm temporarily unavailable. Please try again in a moment.";
    }
  }
}
