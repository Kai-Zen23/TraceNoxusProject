
import 'game_enum.dart';

class UserManagementModel {
  final String id;
  String username;
  String email;
  String role; // 'admin' or 'user'
  List<GamePlayed> gamesPlayed;

  UserManagementModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.gamesPlayed,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    var gamesList = <GamePlayed>[];
    if (json['games_played'] != null) {
      if (json['games_played'] is String) {
        final gamesString = json['games_played'] as String;
        if (gamesString.isNotEmpty) {
           final gamesNames = gamesString.split(',').map((e) => e.trim()).toList();
           for (var name in gamesNames) {
             for (var game in GamePlayed.values) {
               if (game.displayName.toLowerCase() == name.toLowerCase() || 
                   game.name.toLowerCase() == name.toLowerCase()) {
                 gamesList.add(game);
               }
               // Special handling for legacy 'tekken' vs 'TEKKEN 8'
               if (name.toLowerCase() == 'tekken' && game == GamePlayed.tekken8) {
                   gamesList.add(game);
               }
             }
           }
        }
      } else if (json['games_played'] is List) {
        final gamesNames = (json['games_played'] as List).map((e) => e.toString()).toList();
         for (var name in gamesNames) {
             for (var game in GamePlayed.values) {
               if (game.displayName.toLowerCase() == name.toLowerCase() || 
                   game.name.toLowerCase() == name.toLowerCase()) {
                 gamesList.add(game);
               }
             }
           }
      }
    }

    return UserManagementModel(
      id: json['id'].toString(), // Ensure ID is string
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      gamesPlayed: gamesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'games_played': gamesPlayed.map((e) => e.displayName).join(', '), // Sending as comma separated string
    };
  }

  String get gamesPlayedString {
    if (gamesPlayed.isEmpty) return 'None';
    return gamesPlayed.map((game) => game.displayName).join(' / ');
  }
}