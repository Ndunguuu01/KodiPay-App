import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _isTyping = false;
  String? _typingUser;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;
  String? get typingUser => _typingUser;

  MessageProvider() {
    _initTypingListener();
  }

  void _initTypingListener() {
    NotificationService().typingStream.listen((data) {
      if (data['isTyping']) {
        _isTyping = true;
        _typingUser = data['user'];
      } else {
        _isTyping = false;
        _typingUser = null;
      }
      notifyListeners();
    });
  }

  void sendTyping(String room, String userName) {
    NotificationService().sendTyping(room, userName);
  }

  void sendStopTyping(String room, String userName) {
    NotificationService().sendStopTyping(room, userName);
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _messageService.getMessages();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(Message message) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _messageService.sendMessage(message);

    _isLoading = false;
    if (result['success']) {
      await fetchMessages(); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
