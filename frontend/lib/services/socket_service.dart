import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/secure_storage.dart';
import '../utils/constants.dart';

class SocketService {
  late io.Socket socket;

  Future<void> init() async {
    final token = await SecureStorage.getToken();

    socket =
        io.io(AppConstants.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token ?? ''},
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to socket server');
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected from socket server');
    });
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void off(String event) {
    socket.off(event);
  }

  void dispose() {
    socket.dispose();
  }
}
