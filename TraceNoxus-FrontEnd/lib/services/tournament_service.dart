import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/tournament_model.dart';

class TournamentService {
  static const String baseUrl = AppConstants.baseUrl;
  final storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<List<Tournament>> getTournaments() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/tournaments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Tournament.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tournaments');
    }
  }

  Future<List<Match>> getMatches() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/matches/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Match.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load matches');
    }
  }
}
