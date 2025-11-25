// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\services\room_message_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/message_model.dart';

class RoomMessageService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  static const String _baseUrl = AppConstants.baseUrl;

  Future<String?> _token() => _storage.read(key: 'token');

  Future<List<MessageModel>> fetchRoomMessages({String room = 'general'}) async {
    final t = await _token();
    final r = await _dio.get('$_baseUrl/api/room-messages/', queryParameters: {'room': room}, options: Options(headers: {'Authorization': 'Bearer $t'}));
    final data = r.data as List;
    return data.map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<MessageModel> sendRoomMessage({required String content, String room = 'general'}) async {
    final t = await _token();
    final r = await _dio.post('$_baseUrl/api/room-messages/', data: {'room': room, 'content': content}, options: Options(headers: {'Authorization': 'Bearer $t'}));
    return MessageModel.fromJson(Map<String, dynamic>.from(r.data));
  }
}