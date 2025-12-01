import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // TODO: Move this to a secure environment variable in production
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-pro-latest',
      apiKey: _apiKey,
    );
  }

  Future<String> sendMessage(String message, Map<String, dynamic> context) async {
    try {
      // Construct a prompt that includes the context
      final prompt = _buildPrompt(message, context);
      final content = [Content.text(prompt)];
      
      final response = await _model.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      print('Error generating content: $e');
      return "Error: $e"; // Temporary: Show actual error to user
    }
  }

  String _buildPrompt(String userMessage, Map<String, dynamic> context) {
    final userName = context['userName'] ?? 'User';
    final rentAmount = context['rentAmount'];
    final bills = context['bills'] as List<dynamic>? ?? [];
    
    final billSummary = bills.map((b) => 
      "- ${b.type}: KES ${b.amount} (${b.status})"
    ).join('\n');

    return '''
You are a helpful assistant for the KodiPay app, a real estate management platform.
You are talking to a tenant named $userName.

Context:
- Rent Amount: KES $rentAmount
- Bills:
$billSummary

User Message: "$userMessage"

Respond to the user in a friendly and helpful manner. Use the context provided to answer questions about their rent or bills if asked. Keep the response concise (under 3 sentences if possible).
''';
  }
}
