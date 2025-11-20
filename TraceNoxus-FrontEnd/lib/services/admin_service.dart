import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AdminService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _baseUrl = AppConstants.baseUrl;

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // Get all users (admin only)
  Future<Map<String, dynamic>> getAllUsers({
    String? role,
    bool? isVerified,
    bool? isSuperuser,
    bool? isActive,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (isVerified != null) queryParams['is_verified'] = isVerified.toString();
      if (isSuperuser != null) queryParams['is_superuser'] = isSuperuser.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final response = await _dio.get(
        '$_baseUrl/api/users/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to fetch users');
      }
      throw Exception('Failed to fetch users: ${e.message}');
    }
  }

  // Get user by ID (admin only)
  Future<UserModel> getUserById(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '$_baseUrl/api/users/$userId/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to fetch user');
      }
      throw Exception('Failed to fetch user: ${e.message}');
    }
  }

  // Update user (admin only)
  Future<UserModel> updateUser(
    int userId, {
    String? username,
    String? firstName,
    String? lastName,
    String? role,
    bool? isVerified,
    bool? isActive,
    bool? isStaff,
    bool? isSuperuser,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (role != null) data['role'] = role;
      if (isVerified != null) data['is_verified'] = isVerified;
      if (isActive != null) data['is_active'] = isActive;
      if (isStaff != null) data['is_staff'] = isStaff;
      if (isSuperuser != null) data['is_superuser'] = isSuperuser;

      final response = await _dio.patch(
        '$_baseUrl/api/users/$userId/',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to update user');
      }
      throw Exception('Failed to update user: ${e.message}');
    }
  }

  // Delete user (admin only)
  Future<void> deleteUser(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      await _dio.delete(
        '$_baseUrl/api/users/$userId/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Failed to delete user');
      }
      throw Exception('Failed to delete user: ${e.message}');
    }
  }
}

