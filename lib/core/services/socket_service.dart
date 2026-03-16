import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class SocketService {
  io.Socket? _socket;
  final Map<String, List<Function>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.serverOrigin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('[SocketService] Connect error: $error');
    });

    // Re-register saved listeners
    _listeners.forEach((event, callbacks) {
      for (final cb in callbacks) {
        _socket!.on(event, (data) => cb(data));
      }
    });
  }

  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
    _socket?.on(event, (data) => callback(data));
  }

  void off(String event) {
    _listeners.remove(event);
    _socket?.off(event);
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
  }
}
