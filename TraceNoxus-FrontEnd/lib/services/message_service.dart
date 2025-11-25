// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\services\message_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/message_model.dart';

class MessageService {
  final Dio _dio = Dio();
  static const String _baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<MessageModel>> fetchMessages({int? otherUserId}) async {
    final token = await _getToken();
    final response = await _dio.get(
      '$_baseUrl/api/messages/',
      queryParameters: otherUserId != null ? {'user_id': otherUserId} : null,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data as List;
    return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MessageModel> sendMessage({required int receiverId, required String content}) async {
    final token = await _getToken();
    final response = await _dio.post(
      '$_baseUrl/api/messages/',
      data: {'receiver': receiverId, 'content': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }
  Future<void> deleteMessage(int messageId) async {
    final token = await _getToken();
    await _dio.delete(
      '$_baseUrl/api/messages/$messageId/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteConversation(int otherUserId) async {
    final token = await _getToken();
    await _dio.delete(
      '$_baseUrl/api/messages/conversation/$otherUserId/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}