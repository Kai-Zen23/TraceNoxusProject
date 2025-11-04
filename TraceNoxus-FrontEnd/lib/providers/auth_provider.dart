import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get email => _email;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = await _authService.isAuthenticated();
    notifyListeners();
  }

  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final request = RegisterRequest(
      email: email,
      username: username,
      password: password,
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

    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _email = null;
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
} 