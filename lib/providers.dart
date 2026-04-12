import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  
  String? _currentUsername;
  String? _token;
  bool _isLoading = false;
  String? _error;

  String? get currentUsername => _currentUsername;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;

  AuthProvider({required this.apiService});

  Future<void> init() async {
    await apiService.loadToken();
    _token = apiService.getToken();
    if (_token != null) {
      try {
        final profile = await apiService.getOwnProfile();
        _currentUsername = profile.username;
      } catch (e) {
        _token = null;
        await apiService.clearToken();
      }
    }
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.register(username, email, password);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await apiService.login(username, password);
      _token = token;
      _currentUsername = username;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.verifyOtp(email, otp);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.resetPassword(email, otp, newPassword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUsername = null;
    await apiService.clearToken();
    notifyListeners();
  }
}

class MessagesProvider extends ChangeNotifier {
  final ApiService apiService;
  WebSocketService? webSocketService;

  List<Conversation> _conversations = [];
  Map<String, List<Message>> _conversationMessages = {};
  Map<int, Message> _allMessages = {};
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MessagesProvider({required this.apiService});

  void initWebSocket(String token) {
    webSocketService = WebSocketService(token: token);
    webSocketService?.onMessage((message) {
      _allMessages[message.id] = message;
      if (!_conversationMessages.containsKey(message.sender)) {
        _conversationMessages[message.sender] = [];
      }
      if (!_conversationMessages[message.sender]!.any((m) => m.id == message.id)) {
        _conversationMessages[message.sender]!.insert(0, message);
      }
      notifyListeners();
    });

    webSocketService?.onStatusUpdate((update) {
      final messageId = update['messageId'];
      if (_allMessages.containsKey(messageId)) {
        final msg = _allMessages[messageId]!;
        _allMessages[messageId] = Message(
          id: msg.id,
          sender: msg.sender,
          recipient: msg.recipient,
          content: msg.content,
          status: update['status'],
          sentAt: msg.sentAt,
          deliveredAt: update['deliveredAt'] != null
              ? DateTime.parse(update['deliveredAt'])
              : msg.deliveredAt,
          seenAt:
              update['seenAt'] != null ? DateTime.parse(update['seenAt']) : msg.seenAt,
          attachmentUrl: msg.attachmentUrl,
          attachmentName: msg.attachmentName,
          attachmentType: msg.attachmentType,
          attachmentSize: msg.attachmentSize,
        );
        notifyListeners();
      }
    });

    webSocketService?.connect();
  }

  Future<void> loadConversations({int page = 0, int size = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await apiService.getConversations(page: page, size: size);
      _conversations = result.content;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Message>> loadConversation(String withUser, {int page = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await apiService.getConversation(withUser, page: page);
      if (!_conversationMessages.containsKey(withUser)) {
        _conversationMessages[withUser] = [];
      }
      for (var msg in result.content) {
        _allMessages[msg.id] = msg;
      }
      _conversationMessages[withUser] = result.content;
      _isLoading = false;
      notifyListeners();
      return result.content;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  List<Message> getConversationMessages(String withUser) {
    return _conversationMessages[withUser] ?? [];
  }

  void sendMessage(String recipient, String content,
      {String? attachmentUrl,
      String? attachmentName,
      String? attachmentType,
      int? attachmentSize}) {
    if (webSocketService?.isConnected ?? false) {
      webSocketService?.sendMessage(
        recipient,
        content,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentType: attachmentType,
        attachmentSize: attachmentSize,
      );
    }
  }

  void markAsDelivered(int messageId) {
    if (webSocketService?.isConnected ?? false) {
      webSocketService?.markAsDelivered(messageId);
    }
  }

  void markAsSeen(int messageId) {
    if (webSocketService?.isConnected ?? false) {
      webSocketService?.markAsSeen(messageId);
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(List<int> fileBytes, String fileName) async {
    try {
      final response = await apiService.uploadAttachment(fileBytes, fileName);
      return {
        'attachmentUrl': response.attachmentUrl,
        'attachmentName': response.attachmentName,
        'attachmentType': response.attachmentType,
        'attachmentSize': response.attachmentSize,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

class ProfileProvider extends ChangeNotifier {
  final ApiService apiService;

  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileProvider({required this.apiService});

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await apiService.getOwnProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String? displayName, String? bio) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await apiService.updateProfile(displayName, bio);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadProfilePicture(List<int> fileBytes, String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await apiService.uploadProfilePicture(fileBytes, fileName);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

class PresenceProvider extends ChangeNotifier {
  final ApiService apiService;
  WebSocketService? webSocketService;

  Map<String, bool> _presenceStatus = {};
  bool _isLoading = false;

  Map<String, bool> get presenceStatus => _presenceStatus;
  bool get isLoading => _isLoading;

  PresenceProvider({required this.apiService});

  void initWebSocket(WebSocketService websocket) {
    webSocketService = websocket;
    webSocketService?.onPresence((presence) {
      _presenceStatus[presence['username']] = presence['online'] ?? false;
      notifyListeners();
    });
  }

  Future<bool> checkPresence(String username) async {
    return await apiService.checkPresence(username);
  }

  Future<void> loadOnlineUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final users = await apiService.getOnlineUsers();
      _presenceStatus.clear();
      for (var user in users) {
        _presenceStatus[user] = true;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
