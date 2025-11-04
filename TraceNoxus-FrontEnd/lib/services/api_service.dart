import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl; // Centralized
  final storage = const FlutterSecureStorage();

  // Get stored token
  Future<String?> getToken() async {
    return await storage.read(key: 'access_token');
  }

  // Login (Django: /api/login/)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Store tokens (align with other services' key names)
        await storage.write(key: 'token', value: data['access']);
        await storage.write(key: 'refresh', value: data['refresh']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to login');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response from server');
      }
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // Register (Django: /api/register/)
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Registration returns message; tokens may not be returned. Store if present.
        if (data['access'] != null) {
          await storage.write(key: 'token', value: data['access']);
        }
        if (data['refresh'] != null) {
          await storage.write(key: 'refresh', value: data['refresh']);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic>) {
          // Handle field-specific errors
          final errorMessages = <String>[];
          error.forEach((key, value) {
            if (value is List) {
              errorMessages.add('$key: ${value.join(', ')}');
            } else {
              errorMessages.add('$key: $value');
            }
          });
          throw Exception(errorMessages.join('\n'));
        }
        throw Exception(error['error'] ?? 'Failed to register');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response from server');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // Get user profile (Django: /api/user/)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response from server');
      }
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Since there's no explicit logout endpoint, we'll just clear the tokens
      await storage.delete(key: 'token');
      await storage.delete(key: 'refresh');
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh');
      if (refreshToken == null) throw Exception('No refresh token found');

      final response = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'token', value: data['access']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to refresh token');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response from server');
      }
      throw Exception('Failed to connect to the server: $e');
    }
  }
} 