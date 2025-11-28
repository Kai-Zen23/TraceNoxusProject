import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class FriendRequestsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _baseUrl = AppConstants.baseUrl;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _outgoing = [];
  int _seenCount = 0;
  String? _userId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get incoming => _incoming;
  List<Map<String, dynamic>> get outgoing => _outgoing;
  
  int get badgeCount => (_incoming.length - _seenCount).clamp(0, _incoming.length);

  void setUserId(int id) {
    _userId = id.toString();
  }

  Future<void> markAsSeen() async {
    _seenCount = _incoming.length;
    if (_userId != null) {
      await _storage.write(key: 'seen_friends_$_userId', value: _seenCount.toString());
    }
    notifyListeners();
  }

  Future<String?> _token() async => _storage.read(key: 'token');

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadIncoming(), _loadOutgoing()]);
      
      if (_userId != null) {
        final savedSeen = await _storage.read(key: 'seen_friends_$_userId');
        if (savedSeen != null) {
          _seenCount = int.tryParse(savedSeen) ?? 0;
        }
      }

      if (_incoming.length < _seenCount) {
        _seenCount = _incoming.length;
        if (_userId != null) {
          await _storage.write(key: 'seen_friends_$_userId', value: _seenCount.toString());
        }
      }
    } catch (e) {
      _error = 'Failed to load friend requests';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadIncoming() async {
    final t = await _token();
    final r = await _dio.get(
      '$_baseUrl/api/friend-requests/',
      queryParameters: {'type': 'incoming'},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    _incoming = List<Map<String, dynamic>>.from(r.data);
  }

  Future<void> _loadOutgoing() async {
    final t = await _token();
    final r = await _dio.get(
      '$_baseUrl/api/friend-requests/',
      queryParameters: {'type': 'outgoing'},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    _outgoing = List<Map<String, dynamic>>.from(r.data);
  }

  Future<void> sendRequest(int receiverId) async {
    final t = await _token();
    await _dio.post(
      '$_baseUrl/api/friend-requests/',
      data: {'receiver': receiverId},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    await refresh();
  }

  Future<void> accept(int requestId) async {
    final t = await _token();
    await _dio.post(
      '$_baseUrl/api/friend-requests/$requestId/accept/',
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    await refresh();
  }

  Future<void> reject(int requestId) async {
    final t = await _token();
    await _dio.post(
      '$_baseUrl/api/friend-requests/$requestId/reject/',
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    await refresh();
  }
}