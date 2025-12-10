// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\providers\room_chat_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../services/room_message_service.dart';
import '../models/message_model.dart';
import '../core/services/sound_service.dart';
import 'auth_provider.dart';

class RoomChatProvider extends ChangeNotifier {
  final RoomMessageService _service = RoomMessageService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _error;
  List<MessageModel> _messages = [];
  IOWebSocketChannel? _channel;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MessageModel> get messages => _messages;

  int? _selfId;

  void setSelf(AuthProvider auth) {
    _selfId = auth.currentUser?.id;
  }

  Future<void> load({String room = 'general'}) async {
    _isLoading = true; _error = null; notifyListeners();
    try { _messages = await _service.fetchRoomMessages(room: room); }
    catch (_) { _error = 'Failed to load room'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> connect({String room = 'general'}) async {
    final t = await _storage.read(key: 'token');
    final uri = Uri.parse(AppConstants.baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final hostPort = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    final wsUrl = Uri.parse('$wsScheme://$hostPort/ws/chat/$room/?token=$t');
    _channel = IOWebSocketChannel.connect(wsUrl);
    _channel!.stream.listen((event) {
      try {
        final data = jsonDecode(event);
        final msg = MessageModel.fromJson(Map<String, dynamic>.from(data));
        
        if (_selfId != null && msg.sender != _selfId) {
          SoundService().playNotificationSound();
        }

        _messages = [..._messages, msg];
        notifyListeners();
      } catch (_) {}
    }, onError: (e) {
      _error = 'WebSocket error';
      notifyListeners();
    }, onDone: () {
      _error = 'WebSocket closed';
      notifyListeners();
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> send(String content, {String room = 'general'}) async {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'message': content}));
    }
  }
}
