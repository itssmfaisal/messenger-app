import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models.dart';

class WebSocketService {
  static const String wsBaseUrl = 'https://messenger.otaworkstation.shop/ws';
  
  String? _token;
  StompClient? _client;

  final List<Function(Message)> _messageListeners = [];
  final List<Function(Map<String, dynamic>)> _statusUpdateListeners = [];
  final List<Function(Map<String, dynamic>)> _errorListeners = [];
  final List<Function(String)> _statusListeners = [];
  final List<Function(Map<String, dynamic>)> _presenceListeners = [];

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  WebSocketService({required String token}) {
    _token = token;
  }

  void connect() {
    if (_isConnected || _token == null || _token!.isEmpty) {
      return;
    }

    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsBaseUrl,
        reconnectDelay: const Duration(seconds: 5),
        stompConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        onConnect: _onConnect,
        onDisconnect: (frame) {
          _isConnected = false;
        },
        onStompError: (frame) {
          _isConnected = false;
          final error = <String, dynamic>{
            'error': frame.body ?? 'STOMP error',
          };
          for (final listener in _errorListeners) {
            listener(error);
          }
        },
        onWebSocketError: (error) {
          _isConnected = false;
          final payload = <String, dynamic>{
            'error': error.toString(),
          };
          for (final listener in _errorListeners) {
            listener(payload);
          }
        },
      ),
    );

    _client?.activate();
  }

  void sendMessage(String recipient, String content,
      {String? attachmentUrl,
      String? attachmentName,
      String? attachmentType,
      int? attachmentSize}) {
    if (!isConnected || _client == null) {
      throw StateError('WebSocket is not connected');
    }

    final payload = <String, dynamic>{
      'recipient': recipient,
      'content': content,
    };

    if (attachmentUrl != null) payload['attachmentUrl'] = attachmentUrl;
    if (attachmentName != null) payload['attachmentName'] = attachmentName;
    if (attachmentType != null) payload['attachmentType'] = attachmentType;
    if (attachmentSize != null) payload['attachmentSize'] = attachmentSize;

    _client!.send(
      destination: '/app/chat.send',
      body: jsonEncode(payload),
    );
  }

  void markAsDelivered(int messageId) {
    if (!isConnected || _client == null) return;
    _client!.send(
      destination: '/app/chat.delivered',
      body: jsonEncode({'messageId': messageId}),
    );
  }

  void markAsSeen(int messageId) {
    if (!isConnected || _client == null) return;
    _client!.send(
      destination: '/app/chat.seen',
      body: jsonEncode({'messageId': messageId}),
    );
  }

  void sendJoin() {
    if (!isConnected || _client == null) return;
    _client!.send(destination: '/app/chat.join', body: '');
  }

  void onMessage(Function(Message) listener) {
    _messageListeners.add(listener);
  }

  void onStatusUpdate(Function(Map<String, dynamic>) listener) {
    _statusUpdateListeners.add(listener);
  }

  void onError(Function(Map<String, dynamic>) listener) {
    _errorListeners.add(listener);
  }

  void onStatus(Function(String) listener) {
    _statusListeners.add(listener);
  }

  void onPresence(Function(Map<String, dynamic>) listener) {
    _presenceListeners.add(listener);
  }

  void disconnect() {
    _isConnected = false;
    _client?.deactivate();
    _client = null;
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;

    _client?.subscribe(
      destination: '/user/queue/messages',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          final message = Message.fromJson(data);
          for (final listener in _messageListeners) {
            listener(message);
          }
        } catch (_) {
          // Ignore malformed payloads from server.
        }
      },
    );

    _client?.subscribe(
      destination: '/user/queue/status-updates',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          for (final listener in _statusUpdateListeners) {
            listener(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      },
    );

    _client?.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          for (final listener in _errorListeners) {
            listener(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      },
    );

    _client?.subscribe(
      destination: '/topic/status',
      callback: (frame) {
        final text = frame.body ?? '';
        for (final listener in _statusListeners) {
          listener(text);
        }
      },
    );

    _client?.subscribe(
      destination: '/topic/presence',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          for (final listener in _presenceListeners) {
            listener(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      },
    );

    sendJoin();
  }
}
