import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../auth/auth_storage.dart';
import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect() {
    final token = AuthStorage().token;
    if (token == null) return;

    final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          _controller.add(json);
        } catch (_) {}
      },
      onDone: () => _channel = null,
      onError: (_) => _channel = null,
      cancelOnError: false,
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
