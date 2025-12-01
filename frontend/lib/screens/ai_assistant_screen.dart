import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../providers/bill_provider.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // {sender: 'user'/'ai', text: '...'}
  final AIService _aiService = AIService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _messages.add({
      'sender': 'ai',
      'text': 'Hi! I\'m your KodiPay Assistant. Ask me about rent, bills, or maintenance!'
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _isLoading = true;
    });
    _controller.clear();

    // Gather Context Data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);

    // Ensure data is loaded
    if (leaseProvider.leases.isEmpty && authProvider.userId != null) {
      await leaseProvider.fetchLeases(authProvider.userId!);
    }
    if (billProvider.bills.isEmpty && authProvider.userId != null) {
      await billProvider.fetchBillsByTenant(authProvider.userId!);
    }

    final activeLease = leaseProvider.leases.firstWhere(
      (l) => l.status == 'active' || l.status == 'pending',
      orElse: () => leaseProvider.leases.isNotEmpty ? leaseProvider.leases.first : null as dynamic,
    );

    final contextData = {
      'userName': authProvider.userName,
      'rentAmount': activeLease?.rentAmount ?? 0.0,
      'bills': billProvider.bills,
    };

    try {
      final response = await _aiService.sendMessage(userText, contextData);
      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': 'Sorry, something went wrong.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Assistant'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppConstants.primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
