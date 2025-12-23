import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class AdminService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // final String? _baseUrl = dotenv.env['API_URL'];

  AdminService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'error': 'No token found'};
      }

      // UserListView returns stats in the response
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
        return response.data; // Contains total_users, verified_users, etc.
      } else {
        return {'error': 'Failed to fetch stats: ${response.statusCode}'};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {'error': e.response?.data['detail'] ?? 'Server error'};
      }
      return {'error': 'Connection error: ${e.message}'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    return getDashboardStats(); // Reusing the same endpoint as it returns user list + stats
  }

  Future<void> deleteUser(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await _dio.delete(
        '/api/users/$userId/',
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
