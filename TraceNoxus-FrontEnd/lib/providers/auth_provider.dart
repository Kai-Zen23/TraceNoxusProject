import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;
  String? _email;

  // Role switching fields
  String? _virtualRole; // null = use actual role, 'user' = override to user mode
  String? _originalRole; // Store original role for safety check


  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  
  // Role switching getters
  String get currentRole => _virtualRole ?? _currentUser?.role ?? 'user';
  bool get isAdmin => currentRole.toLowerCase() == 'admin';
  bool get isUser => currentRole.toLowerCase() == 'user';
  bool get isInUserMode => _virtualRole == 'user';
  bool get canSwitchRoles => _originalRole == 'admin' || _currentUser?.role.toLowerCase() == 'admin';
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get email => _email;

  // Legacy getter for backward compatibility
  UserModel? get user => _currentUser;

  AuthProvider() {
    // _checkAuthStatus(); // Removed from constructor
  }

  // Initialize from stored data (RBAC pattern)
  Future<void> initialize() async {
    // Avoid notifying listeners synchronously during creation
    // _isLoading = true; // Don't set this here if it triggers notifyListeners immediately

    await _checkAuthStatus(); // Check auth status first

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('access_token');
      final refresh = prefs.getString('refresh') ?? prefs.getString('refresh_token');
      final userJson = prefs.getString('user_data');
      
      // Load virtual role if exists
      _virtualRole = prefs.getString('virtual_role');
      _originalRole = prefs.getString('original_role');

      if (token != null && userJson != null) {
        _accessToken = token;
        _refreshToken = refresh;
        _currentUser = UserModel.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(userJson) as Map,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await logout();
    } finally {
      // _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAuthStatus() async {
    // Check auth status - isAuthenticated is a getter, no need to set it
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      _currentUser = null;
      _accessToken = null;
    }
    // notifyListeners(); // Removed to prevent side effects during initialization
  }

  Future<bool> register(String email, String username, String password, {String? phoneNumber}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final request = RegisterRequest(
      email: email,
      username: username,
      password: password,
      phoneNumber: phoneNumber,
    );

    final response = await _authService.register(request);
    _isLoading = false;

    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }

    _email = email; // Store email for OTP verification
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    if (_email == null) {
      _error = 'Email not found. Please register first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final request = OtpVerificationRequest(
      email: _email!,
      otp: otp,
    );

    final response = await _authService.verifyOtp(request);
    _isLoading = false;

    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> resendOtp() async {
    if (_email == null) {
      _error = 'Email not found. Please register first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.resendOtp(_email!);
    _isLoading = false;

    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final request = LoginRequest(
      email: email,
      password: password,
    );

    final response = await _authService.login(request);
    _isLoading = false;

    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }

    // Store user data from login response (RBAC pattern)
    if (response.user != null) {
      _currentUser = UserModel.fromJson(response.user!);
      _accessToken = response.token;
      _refreshToken = response.refresh;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _accessToken!);
      await prefs.setString('refresh', _refreshToken!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    } else {
      // Try to get user data from API
      try {
        final userData = await _authService.getUserData();
        _currentUser = UserModel.fromJson(userData);
        _accessToken = await _authService.getToken();
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('token', _accessToken!);
          await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
        }
      } catch (e) {
        debugPrint('Could not fetch user data: $e');
      }
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _error = null;
    
    // Clear role switching state
    _virtualRole = null;
    _originalRole = null;

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('virtual_role');
    await prefs.remove('original_role');

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Forgot Password Flow
  Future<bool> sendForgotPasswordOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final response = await _authService.sendForgotPasswordOtp(email);
    _isLoading = false;
    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }
    _email = email;
    notifyListeners();
    return true;
  }

  Future<bool> verifyForgotPasswordOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final response = await _authService.verifyForgotPasswordOtp(email, otp);
    _isLoading = false;
    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final response = await _authService.resetPassword(email, newPassword);
    _isLoading = false;
    if (response.error != null) {
      _error = response.error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  // Refresh access token (RBAC pattern)
  Future<bool> refreshAccessToken() async {
    // Check if refresh token exists
    if (_refreshToken == null) return false;

    try {
      await _authService.refreshToken();
      _accessToken = await _authService.getToken();

      if (_accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _accessToken!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Role switching methods
  /// Switch from admin mode to user mode
  /// Only works if current user is actually an admin
  Future<void> switchToUserMode() async {
    if (_currentUser?.role.toLowerCase() == 'admin') {
      _originalRole = _currentUser!.role;
      _virtualRole = 'user';
      
      // Persist virtual role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('virtual_role', _virtualRole!);
      await prefs.setString('original_role', _originalRole!);
      
      notifyListeners();
    }
  }

  /// Switch back to admin mode from user mode
  /// Clears the virtual role override
  Future<void> switchToAdminMode() async {
    _virtualRole = null;
    
    // Clear persisted virtual role
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('virtual_role');
    await prefs.remove('original_role');
    
    notifyListeners();
  }
}
