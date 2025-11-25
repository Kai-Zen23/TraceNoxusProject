import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class FriendService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  static const String _baseUrl = AppConstants.baseUrl;

  Future<String?> _token() => _storage.read(key: 'token');

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final t = await _token();
    final r = await _dio.get('$_baseUrl/api/users/all/', options: Options(headers: {'Authorization': 'Bearer $t'}));
    
    dynamic data = r.data;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      data = data['results'];
    }
    
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final t = await _token();
    final r = await _dio.get('$_baseUrl/api/friends/', options: Options(headers: {'Authorization': 'Bearer $t'}));
    return List<Map<String, dynamic>>.from(r.data);
  }

  Future<void> addFriend(int friendId) async {
    final t = await _token();
    await _dio.post('$_baseUrl/api/friends/', data: {'friend': friendId}, options: Options(headers: {'Authorization': 'Bearer $t'}));
  }

  Future<void> removeFriend(int friendshipId) async {
    final t = await _token();
    await _dio.delete('$_baseUrl/api/friends/$friendshipId/', options: Options(headers: {'Authorization': 'Bearer $t'}));
  }
}