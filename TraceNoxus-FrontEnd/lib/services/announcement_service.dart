import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final String baseUrl = 'http://10.0.2.2:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<Announcement>> getAnnouncements() async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/announcements/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Announcement.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  Future<Announcement> createAnnouncement(String title, String content) async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/announcements/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return Announcement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create announcement');
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/announcements/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete announcement');
    }
  }
}
