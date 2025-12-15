import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
  Set<int> get friendIds =>
      _friendRecords.map((e) => e['friend'] as int).toSet();

  List<Map<String, dynamic>> get friends {
    final ids = friendIds;
    return _allUsers.where((u) => ids.contains(u['id'])).toList();
  }

  Future<void> loadAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allUsers = await _service.fetchAllUsers();
    } catch (e) {
      _error = 'Failed to load users: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _friendRecords = await _service.fetchFriends();
    } catch (e) {
      _error = 'Failed to load friends';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFriend(int userId) async {
    try {
      await _service.addFriend(userId);
      await loadFriends();
    } on DioException catch (e) {
      print('DioError adding friend: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
      }
      _error = 'Failed to add friend: ${e.response?.statusCode}';
      notifyListeners();
    } catch (e) {
      print('Error adding friend: $e');
      _error = 'Failed to add friend';
      notifyListeners();
    }
  }

  Future<void> removeFriendByUserId(int userId) async {
    try {
      print('DEBUG: Attempting to remove friend with userId: $userId. Available records: ${_friendRecords.length}');
      
      final rec = _friendRecords.firstWhere((r) {
        // Robust comparison (handle int vs string from JSON)
        final friendId = r['friend'];
        return friendId.toString() == userId.toString();
      },
          orElse: () => {});
      
      if (rec.isEmpty) {
        print('Error: No friendship record found for user $userId');
        _error = 'Friendship not found';
        notifyListeners();
        return;
      }
      
      print('DEBUG: Removing friendship. Record: $rec');
      await _service.removeFriend(rec['id'] as int);
      await loadFriends();
      await loadAllUsers(); // Refresh all users to update Explore/Friends lists
    } on DioException catch (e) {
      print('DioError removing friend: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
      }
      _error = 'Failed to remove friend: ${e.response?.statusCode}';
      notifyListeners();
    } catch (e) {
      print('Error removing friend: $e');
      _error = 'Failed to remove friend';
      notifyListeners();
    }
  }
}
