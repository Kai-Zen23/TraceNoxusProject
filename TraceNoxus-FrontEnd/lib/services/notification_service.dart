import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  NotificationService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/api/notifications/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          data = responseData['results'];
        } else if (responseData is List) {
          data = responseData;
        } else {
          throw Exception('Unexpected response format');
        }
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMessage;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail'] ?? data['message'] ?? 'Server error: ${e.message}';
      } else if (data is List) {
        errorMessage = data.join('\n');
      } else {
        errorMessage = data?.toString() ?? 'Server error: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<NotificationModel> createNotification(String title, String message, {int? recipientId}) async {
    try {
      final token = await _getToken();
      final data = {
        'title': title,
        'message': message,
        if (recipientId != null) 'recipient': recipientId,
      };

      final response = await _dio.post(
        '/api/notifications/',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return NotificationModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create notification: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMessage;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail'] ?? data['message'] ?? 'Server error: ${e.message}';
      } else if (data is List) {
        errorMessage = data.join('\n');
      } else {
        errorMessage = data?.toString() ?? 'Server error: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
