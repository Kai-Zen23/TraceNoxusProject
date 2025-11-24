// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\providers\room_chat_provider.dart
import 'package:flutter/material.dart';
import '../services/room_message_service.dart';
import '../models/message_model.dart';

class RoomChatProvider extends ChangeNotifier {
  final RoomMessageService _service = RoomMessageService();
  bool _isLoading = false;
  String? _error;
  List<MessageModel> _messages = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MessageModel> get messages => _messages;

  Future<void> load({String room = 'general'}) async {
    _isLoading = true; _error = null; notifyListeners();
    try { _messages = await _service.fetchRoomMessages(room: room); }
    catch (_) { _error = 'Failed to load room'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> send(String content, {String room = 'general'}) async {
    final m = await _service.sendRoomMessage(content: content, room: room);
    _messages = [..._messages, m]; notifyListeners();
  }
}