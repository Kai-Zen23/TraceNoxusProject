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

  String get gamesPlayedString {
    return gamesPlayed.map((game) => game.displayName).join(' / ');
  }
}
