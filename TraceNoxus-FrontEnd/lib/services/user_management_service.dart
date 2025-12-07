import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/user_management_model.dart';

class UserManagementService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserManagementService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<UserManagementModel>> getUsers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await _dio.get(
        '/api/users/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data.containsKey('results') && data['results'] is List) {
          final List<dynamic> results = data['results'];
          return results.map((json) => UserManagementModel.fromJson(json)).toList();
        } else {
           // Fallback if structure is different or results is missing
           throw Exception('Invalid response format: results key missing or not a list');
        }
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await _dio.patch(
        '/api/users/$id/',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await _dio.delete(
        '/api/users/$id/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
