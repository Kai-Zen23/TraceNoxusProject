// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\providers\friend_provider.dart
import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _service = FriendService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _friendRecords = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  Set<int> get friendIds => _friendRecords.map((e) => e['friend'] as int).toSet();

  Future<void> loadAllUsers() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _allUsers = await _service.fetchAllUsers();
    } catch (e) { _error = 'Failed to load users: $e'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> loadFriends() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _friendRecords = await _service.fetchFriends();
    } catch (e) { _error = 'Failed to load friends'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> addFriend(int userId) async {
    await _service.addFriend(userId);
    await loadFriends();
  }

  Future<void> removeFriendByUserId(int userId) async {
    final rec = _friendRecords.firstWhere((r) => r['friend'] == userId, orElse: () => {});
    if (rec.isEmpty) return;
    await _service.removeFriend(rec['id'] as int);
    await loadFriends();
  }
}