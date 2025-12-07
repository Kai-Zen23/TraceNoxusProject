import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assuming you have an endpoint to fetch user data
      final response = await _authService.getUserData();
      _user = UserModel.fromJson(response);
    } catch (e) {
      _error = 'Failed to load user data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String name,
    int? age,
    dynamic profileImageFile, // File? type, but dynamic for now
    String? gamesPlayed,
    String? competitiveLevel,
    String? preferredRoles,
    bool removeProfileImage = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authService.updateUserProfile(
        name: name,
        age: age,
        profileImageFile: profileImageFile,
        gamesPlayed: gamesPlayed,
        competitiveLevel: competitiveLevel,
        preferredRoles: preferredRoles,
        removeProfileImage: removeProfileImage,
      );
      _user = UserModel.fromJson(response);
    } catch (e) {
      _error = 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.deleteUserProfile();
      _user = null;
    } catch (e) {
      _error = 'Failed to delete profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
