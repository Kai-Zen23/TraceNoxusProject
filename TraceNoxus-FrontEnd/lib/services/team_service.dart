import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/team_model.dart';

class TeamService {
  static const String baseUrl = AppConstants.baseUrl;
  final storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<List<Team>> getTeams() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/teams/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Team.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<Team> getTeam(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/teams/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load team');
    }
  }

  Future<Team> createTeam(String name, String description) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/teams/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create team');
    }
  }

  Future<void> joinTeam(int teamId) async {
    // Implement join logic if needed, or just add member via update
    // For now, assuming admin adds members or separate endpoint
  }

  Future<void> deleteTeam(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/teams/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 204 No Content is standard for delete success, but 200/202 are also possible
    if (response.statusCode != 204 && response.statusCode != 200) {
       throw Exception('Failed to delete team: ${response.statusCode}');
    }
  }
}
