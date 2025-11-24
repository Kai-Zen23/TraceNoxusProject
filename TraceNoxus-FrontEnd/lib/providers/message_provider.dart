// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\providers\message_provider.dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import 'auth_provider.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversation({int? otherUserId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _service.fetchMessages(otherUserId: otherUserId);
    } catch (e) {
      _error = 'Failed to load messages';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send({required int receiverId, required String content}) async {
    try {
      final msg = await _service.sendMessage(receiverId: receiverId, content: content);
      _messages = [..._messages, msg];
      notifyListeners();
    } catch (_) {}
  }

  List<Map<String, dynamic>> get conversations {
    final map = <int, List<MessageModel>>{};
    for (final m in _messages) {
      final otherId = _otherId(m);
      map.putIfAbsent(otherId, () => []).add(m);
    }
    final list = <Map<String, dynamic>>[];
    map.forEach((k, v) {
      v.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      list.add({'otherId': k, 'last': v.last.content});
    });
    list.sort((a, b) => (a['otherId'] as int).compareTo(b['otherId'] as int));
    return list;
  }

  int _otherId(MessageModel m) {
    final r = m.receiver ?? _selfId;
    return m.sender == r ? m.sender : (m.sender != _selfId ? m.sender : r);
  }

  int get _selfId => _selfIdCache ?? 0;
  int? _selfIdCache;
  void setSelf(AuthProvider auth) {
    _selfIdCache = auth.currentUser?.id;
  }
}