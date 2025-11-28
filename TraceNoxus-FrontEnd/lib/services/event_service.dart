import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/event_model.dart';

class EventService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  EventService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
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
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    try {
      final token = await _getToken();
      
      // Handle image upload if present (multipart/form-data)
      FormData formData;
      if (eventData.containsKey('background_image') && eventData['background_image'] != null) {
         // If we were handling file uploads, we'd do it here. 
         // For now, let's assume JSON or handle file path if needed.
         // Given the complexity of file upload in Flutter/Dio, let's start with JSON 
         // and assume image is handled separately or as base64 if needed, 
         // but standard Dio FormData is best for files.
         // However, the UI design implies picking an image.
         // Let's stick to JSON for simple fields first, or use FormData if we have a file path.
         
         // For simplicity in this step, I'll send JSON. 
         // If image upload is required, I'll need to adjust to FormData.
         // The backend expects multipart for ImageField usually if sending file.
         // Let's use FormData to be safe if we have a file.
         
         formData = FormData.fromMap(eventData);
         // Note: File handling needs MultipartFile.fromFile. 
         // I will assume the provider handles the conversion to MultipartFile if needed.
      } else {
        // If no file, JSON is fine, but FormData is also fine.
        formData = FormData.fromMap(eventData);
      }

      final response = await _dio.post(
        '/api/events/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Content-Type is set automatically by Dio for FormData
          },
        ),
      );

      if (response.statusCode == 201) {
        return EventModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
  Future<EventModel> updateEvent(int id, Map<String, dynamic> eventData) async {
    try {
      final token = await _getToken();
      
      FormData formData;
      if (eventData.containsKey('background_image') && eventData['background_image'] != null) {
         formData = FormData.fromMap(eventData);
      } else {
        formData = FormData.fromMap(eventData);
      }

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
      throw Exception(e.response?.data['detail'] ?? 'Server error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
