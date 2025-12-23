import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/event_model.dart';

class EventService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  EventService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<EventModel>> fetchEvents() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/api/events/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    try {
      final token = await _getToken();

      final data = Map<String, dynamic>.from(eventData);

      // Handle image upload
      if (data.containsKey('background_image') &&
          data['background_image'] != null) {
        if (data['background_image'] is String) {
          final String path = data['background_image'];
          if (path.isNotEmpty) {
            data['background_image'] = await MultipartFile.fromFile(path);
          }
        }
      }

      final formData = FormData.fromMap(data);

      final response = await _dio.post(
        '/api/events/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        return EventModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<EventModel> updateEvent(int id, Map<String, dynamic> eventData) async {
    try {
      final token = await _getToken();

      final data = Map<String, dynamic>.from(eventData);

      if (data.containsKey('background_image') &&
          data['background_image'] != null) {
        if (data['background_image'] is String) {
          final String path = data['background_image'];
          if (path.isNotEmpty) {
            data['background_image'] = await MultipartFile.fromFile(path);
          }
        }
      }

      final formData = FormData.fromMap(data);

      final response = await _dio.put(
        '/api/events/$id/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EventModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
