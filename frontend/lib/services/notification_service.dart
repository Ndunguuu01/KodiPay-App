import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class NotificationService {
  late IO.Socket socket;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  Future<void> init() async {
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Socket.io
    socket = IO.io(AppConstants.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.io');
      _joinRooms();
    });

    socket.on('new_message', (data) {
      _showNotification(
        'New Message',
        data['content'] ?? 'You have a new message',
      );
    });

    socket.on('typing', (data) {
      _typingController.add({'isTyping': true, 'user': data['user'], 'room': data['room']});
    });

    socket.on('stop_typing', (data) {
      _typingController.add({'isTyping': false, 'user': data['user'], 'room': data['room']});
    });

    socket.on('new_bill', (data) {
      _showNotification(
        'New Bill',
        'You have a new bill of KES ${data['amount']}',
      );
    });

    socket.on('maintenance_update', (data) {
      _showNotification(
        'Maintenance Update',
        'Your request status is now: ${data['status']}',
      );
    });

    socket.on('lease_assigned', (data) {
      _showNotification(
        'New Lease Agreement',
        data['message'] ?? 'You have a new lease to sign.',
      );
    });

    socket.on('lease_signed', (data) {
      _showNotification(
        'Lease Signed',
        data['message'] ?? 'A tenant has signed their lease.',
      );
    });
  }

  Future<void> _joinRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      socket.emit('join_room', 'user_$userId');
    }
  }

  void sendTyping(String room, String userName) {
    socket.emit('typing', {'room': room, 'user': userName});
  }

  void sendStopTyping(String room, String userName) {
    socket.emit('stop_typing', {'room': room, 'user': userName});
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'kodipay_channel',
      'KodiPay Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void disconnect() {
    socket.disconnect();
    _typingController.close();
  }
}
