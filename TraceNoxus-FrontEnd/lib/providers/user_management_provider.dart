import 'package:flutter/foundation.dart';
import '../models/user_management_model.dart';
import '../services/user_management_service.dart';

class UserManagementProvider with ChangeNotifier {
  final UserManagementService _service = UserManagementService();
  List<UserManagementModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserManagementModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _service.getUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(String id, UserManagementModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateUser(id, updatedUser.toJson());
      final index = _users.indexWhere((user) => user.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteUser(id);
      _users.removeWhere((user) => user.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
