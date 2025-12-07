import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import '../models/message_model.dart';
import '../services/message_service.dart';
import 'auth_provider.dart';
import '../core/constants/app_constants.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  AuthProvider? _authProvider;
  
  List<MessageModel> _chatMessages = [];
  List<MessageModel> _allMessages = [];
  bool _isLoading = false;
  String? _error;
  int _seenCount = 0;
  
  // WebSocket Support
  IOWebSocketChannel? _channel;

  List<MessageModel> get messages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get badgeCount => (_allMessages.length - _seenCount).clamp(0, _allMessages.length);

  Future<void> markAsSeen() async {
    _seenCount = _allMessages.length;
    if (_selfId != 0) {
      await _storage.write(key: 'seen_messages_$_selfId', value: _seenCount.toString());
    }
    notifyListeners();
  }

  int get _selfId => _selfIdCache ?? 0;
  int? _selfIdCache;

  void setSelf(AuthProvider auth) {
    _authProvider = auth;
    _selfIdCache = auth.currentUser?.id;
    // print('DEBUG: Set SelfID: $_selfIdCache');
  }

  Future<void> loadAllConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allMessages = await _service.fetchMessages();
      
      if (_selfId != 0) {
        final savedSeen = await _storage.read(key: 'seen_messages_$_selfId');
        if (savedSeen != null) {
          _seenCount = int.tryParse(savedSeen) ?? 0;
        }
      }

      if (_allMessages.length < _seenCount) {
        _seenCount = _allMessages.length;
        if (_selfId != 0) {
          await _storage.write(key: 'seen_messages_$_selfId', value: _seenCount.toString());
        }
      }
      // print('DEBUG: Fetched ${_allMessages.length} total messages. SelfID: $_selfId');
    } catch (e) {
      _error = 'Failed to load conversations';
      print('DEBUG: Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChat(int otherUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _chatMessages = await _service.fetchMessages(otherUserId: otherUserId);
      // print('DEBUG: Fetched ${_chatMessages.length} chat messages. SelfID: $_selfId');
    } catch (e) {
      _error = 'Failed to load chat';
      print('DEBUG: Error loading chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send({required int receiverId, required String content}) async {
    try {
      final msg = await _service.sendMessage(receiverId: receiverId, content: content);
      // We rely on WebSocket to receive the message back, but for immediate UI update we can add it.
      // However, if we add it here AND receive it via WS, we need to handle duplicates.
      // The WS handler checks for duplicates, so it's safe to add here for responsiveness.
      if (!_chatMessages.any((m) => m.id == msg.id)) {
        _chatMessages.add(msg);
      }
      if (!_allMessages.any((m) => m.id == msg.id)) {
        _allMessages.add(msg);
      }
      notifyListeners();
    } catch (_) {}
  }

  List<Map<String, dynamic>> get conversations {
    final map = <int, List<MessageModel>>{};
    for (final m in _allMessages) {
      final otherId = _otherId(m);
      if (otherId != null) {
        map.putIfAbsent(otherId, () => []).add(m);
      }
    }
    // print('DEBUG: Conversations keys: ${map.keys.toList()}');
    final list = <Map<String, dynamic>>[];
    map.forEach((k, v) {
      v.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (v.isNotEmpty) {
        list.add({
          'otherId': k,
          'last': v.last.content,
          'timestamp': v.last.timestamp,
        });
      }
    });
    list.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return list;
  }

  int? _otherId(MessageModel m) {
    if (_selfId == 0) return null;
    final r = m.receiver ?? _selfId;
    final oid = m.sender == r ? m.sender : (m.sender != _selfId ? m.sender : r);
    return oid;
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _service.deleteMessage(messageId);
      _chatMessages.removeWhere((m) => m.id == messageId);
      _allMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Future<void> deleteConversation(int otherUserId) async {
    try {
      await _service.deleteConversation(otherUserId);
      _chatMessages.clear(); // Clear current chat if it's the one being deleted
      _allMessages.removeWhere((msg) => _otherId(msg) == otherUserId); // Remove all messages related to this conversation
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> connect(int otherUserId) async {
    disconnect(); // Ensure no existing connection
    
    final token = _authProvider?.accessToken;
    if (token == null) {
      print('MessageProvider: No token available for WebSocket');
      return;
    }

    final uri = Uri.parse(AppConstants.baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final hostPort = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    final wsUrl = Uri.parse('$wsScheme://$hostPort/ws/dm/$otherUserId/?token=$token');

    print('Connecting to DM WebSocket: $wsUrl');
    try {
      _channel = IOWebSocketChannel.connect(wsUrl);
      _channel!.stream.listen((event) {
        try {
          final data = jsonDecode(event);
          // print('WebSocket received: $data');
          final msg = MessageModel.fromJson(data);
          
          // Update chat messages if relevant
          // Check if message belongs to current chat (either from other user or from self)
          // Since we are connected to a specific DM room (otherUserId), incoming messages should be relevant.
          // But we should verify sender/receiver just in case.
          
          bool isRelevant = (msg.sender == otherUserId || msg.receiver == otherUserId) &&
                            (msg.sender == _selfId || msg.receiver == _selfId);
                            
          if (isRelevant) {
             if (!_chatMessages.any((m) => m.id == msg.id)) {
               _chatMessages.add(msg);
             }
          }

          // Update all messages list
          if (!_allMessages.any((m) => m.id == msg.id)) {
            _allMessages.add(msg);
          }
          
          notifyListeners();
        } catch (e) {
          print('Error parsing DM WebSocket message: $e');
        }
      }, onError: (error) {
        print('DM WebSocket error: $error');
      }, onDone: () {
        print('DM WebSocket closed');
      });
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}
