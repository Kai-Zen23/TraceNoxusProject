import 'package:dio/dio.dart';
import '../models/lesson_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class LessonService {
  final Dio _dio = Dio();
  static final String _baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'token');
  }
  
  Future<List<Lesson>> fetchLessons() async {
    final token = await getToken();
    final response = await _dio.get(
      '$_baseUrl/api/lessons/',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );  
    return (response.data as List).map((json) => Lesson.fromJson(json)).toList();
  }


  Future<void> addLesson(Lesson lesson) async {
    final token = await getToken();
    await _dio.post(
      '$_baseUrl/api/lessons/',
      data: lesson.toJson(),
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> updateLesson(Lesson lesson) async {
    final token = await getToken();
    await _dio.patch(
      '$_baseUrl/api/lessons/${lesson.id}/',
      data: lesson.toJson(),
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> deleteLesson(int lessonId) async {
    final token = await getToken();
    await _dio.delete(
      '$_baseUrl/api/lessons/$lessonId/',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}
