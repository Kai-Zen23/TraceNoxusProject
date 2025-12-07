import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Centralized base URL
  static final String _baseUrl = AppConstants.baseUrl;

  Future<bool> ping() async {
    try {
      final response = await _dio.get('$_baseUrl/api/health/');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/register/',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('error')) {
          return AuthResponse(error: data['error'] ?? 'Registration failed');
        }
        // Flatten DRF serializer errors: {field: [messages...]}
        final messages = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            messages.add("$key: ${value.join(', ')}");
          } else {
            messages.add("$key: $value");
          }
        });
        return AuthResponse(error: messages.join('\n'));
      }
      return AuthResponse(error: 'Registration failed: ${e.message}');
    }
  }

  Future<AuthResponse> verifyOtp(OtpVerificationRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/verify-otp/',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'OTP verification failed',
        );
      }
      return AuthResponse(error: 'OTP verification failed: ${e.message}');
    }
  }

  Future<AuthResponse> resendOtp(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/resend-otp/',
        data: {'email': email},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'Failed to resend OTP',
        );
      }
      return AuthResponse(error: 'Failed to resend OTP: ${e.message}');
    }
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/login/',
        data: request.toJson(),
      );
      
      // Extract user data from response before creating AuthResponse
      Map<String, dynamic>? userData;
      if (response.data is Map && response.data['user'] != null) {
        userData = Map<String, dynamic>.from(response.data['user']);
      }
      
      // Create AuthResponse with user data
      final authResponse = AuthResponse(
        token: response.data['access'],
        refresh: response.data['refresh'],
        message: response.data['message'],
        error: response.data['error'],
        user: userData,
      );
      
      if (authResponse.token != null) {
        await _storage.write(key: 'token', value: authResponse.token);
        await _storage.write(key: 'refresh', value: authResponse.refresh);
      }
      
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'Login failed',
        );
      }
      return AuthResponse(error: 'Login failed: ${e.message}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<AuthResponse> sendForgotPasswordOtp(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/send-forgot-password-otp/',
        data: {'email': email},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'Failed to send OTP',
        );
      }
      return AuthResponse(error: 'Failed to send OTP: ${e.message}');
    }
  }

  Future<AuthResponse> verifyForgotPasswordOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/verify-forgot-password-otp/',
        data: {'email': email, 'otp': otp},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'OTP verification failed',
        );
      }
      return AuthResponse(error: 'OTP verification failed: ${e.message}');
    }
  }

  Future<AuthResponse> resetPassword(String email, String newPassword) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/reset-password/',
        data: {
          'email': email,
          'new_password': newPassword
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return AuthResponse(
          error: e.response?.data['error'] ?? 'Password reset failed',
        );
      }
      return AuthResponse(error: 'Password reset failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '$_baseUrl/api/me/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to fetch user data');
      }
      throw Exception('Failed to fetch user data: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    int? age,
    dynamic profileImageFile,
    String? gamesPlayed,
    String? competitiveLevel,
    String? preferredRoles,
    bool removeProfileImage = false,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('User not authenticated');

    final formData = FormData();
    formData.fields.add(MapEntry('name', name));
    if (age != null) formData.fields.add(MapEntry('age', age.toString()));
    if (gamesPlayed != null) formData.fields.add(MapEntry('games_played', gamesPlayed));
    if (competitiveLevel != null) formData.fields.add(MapEntry('competitive_level', competitiveLevel));
    if (preferredRoles != null) formData.fields.add(MapEntry('preferred_roles', preferredRoles));
    if (removeProfileImage) formData.fields.add(const MapEntry('remove_profile_image', 'true'));
    
    if (profileImageFile != null) {
      formData.files.add(MapEntry(
        'profile_image',
        await MultipartFile.fromFile(profileImageFile.path),
      ));
    }

    final response = await _dio.patch(
      '$_baseUrl/api/me/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    return response.data;
  }

  Future<void> deleteUserProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('User not authenticated');
    await _dio.delete(
      '$_baseUrl/api/me/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh');
      if (refreshToken == null) throw Exception('No refresh token found');

      final response = await _dio.post(
        '$_baseUrl/api/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access'] as String;
        await _storage.write(key: 'token', value: newAccessToken);
      } else {
        throw Exception('Failed to refresh token');
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to refresh token');
      }
      throw Exception('Failed to refresh token: ${e.message}');
    }
  }
}
