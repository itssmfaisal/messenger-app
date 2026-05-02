import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/data/models/chat_message.dart';
import 'package:messenger_app/data/models/presence.dart';
import 'package:messenger_app/data/services/token_storage.dart';

class WebSocketService {
  StompClient? _client;
  String? _token;
  final _tokenStorage = TokenStorage();

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _statusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<PresenceStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get statusUpdateStream => _statusUpdateController.stream;
  Stream<PresenceStatus> get presenceStream => _presenceController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _client?.connected ?? false;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final token = await _tokenStorage.getToken();
    _token = token;
    return token;
  }

  Future<void> connect(String token) async {
    _token = token;
    _client = StompClient(
      config: StompConfig(
        url: AppConstants.wsBaseUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onWebSocketError: (error) {
          _errorController.add(error.toString());
          _connectionStateController.add(false);
        },
        onDisconnect: (_) {
          _connectionStateController.add(false);
        },
        beforeConnect: () async {
          await Future.delayed(const Duration(milliseconds: 200));
        },
      ),
    );
    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    _connectionStateController.add(true);

    _client?.subscribe(
      destination: '/user/queue/messages',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _messageController.add(ChatMessage.fromJson(data));
        }
      },
    );

    _client?.subscribe(
      destination: '/user/queue/status-updates',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _statusUpdateController.add(data);
        }
      },
    );

    _client?.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _errorController.add(data['error'] ?? 'Unknown error');
        }
      },
    );

    _client?.subscribe(
      destination: '/topic/presence',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _presenceController.add(PresenceStatus.fromJson(data));
        }
      },
    );
  }

  void join() {
    _client?.send(destination: '/app/chat.join');
  }

  void sendMessage({
    required String recipient,
    String content = '',
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentType,
    int? attachmentSize,
  }) {
    final body = jsonEncode({
      'recipient': recipient,
      'content': content,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentType != null) 'attachmentType': attachmentType,
      if (attachmentSize != null) 'attachmentSize': attachmentSize,
    });
    _client?.send(destination: '/app/chat.send', body: body);
  }

  void markDelivered(int messageId) {
    _client?.send(
      destination: '/app/chat.delivered',
      body: jsonEncode({'messageId': messageId}),
    );
  }

  void markSeen(int messageId) {
    _client?.send(
      destination: '/app/chat.seen',
      body: jsonEncode({'messageId': messageId}),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusUpdateController.close();
    _presenceController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}
