import '../models.dart';

class WebSocketService {
  static const String wsUrl = 'wss://messenger.otaworkstation.shop/ws';
  
  String? _token;

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
    // WebSocket will be implemented with stomp protocol
    // For now, this is a placeholder
    _isConnected = true;
    print('WebSocket service initialized (token: ${_token?.substring(0, 20)}...)');
  }

  void sendMessage(String recipient, String content,
      {String? attachmentUrl,
      String? attachmentName,
      String? attachmentType,
      int? attachmentSize}) {
    // Will be implemented with STOMP
    print('Send message to $recipient: $content');
  }

  void markAsDelivered(int messageId) {
    print('Mark message $messageId as delivered');
  }

  void markAsSeen(int messageId) {
    print('Mark message $messageId as seen');
  }

  void sendJoin() {
    print('User joined');
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
  }
}
