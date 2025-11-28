import 'package:flutter/foundation.dart';
import '../models/user_management_model.dart';
import '../models/game_enum.dart';

class UserManagementProvider with ChangeNotifier {
  final List<UserManagementModel> _users = [
    UserManagementModel(
      id: '1',
      username: '@kalitz3',
      email: 'kalitz3@example.com',
      role: 'user',
      gamesPlayed: [GamePlayed.valorant],
    ),
    UserManagementModel(
      id: '2',
      username: '@danez3',
      email: 'danez3@example.com',
      role: 'admin',
      gamesPlayed: [GamePlayed.tekken8],
    ),
    UserManagementModel(
      id: '3',
      username: '@judez3',
      email: 'judez3@example.com',
      role: 'user',
      gamesPlayed: [GamePlayed.valorant, GamePlayed.leagueOfLegends],
    ),
    UserManagementModel(
      id: '4',
      username: '@jimargz3',
      email: 'jimargz3@example.com',
      role: 'user',
      gamesPlayed: [GamePlayed.mobileLegends],
    ),
    UserManagementModel(
      id: '5',
      username: '@jaymarkz3',
      email: 'jaymarkz3@example.com',
      role: 'user',
      gamesPlayed: [GamePlayed.valorant],
    ),
  ];

  List<UserManagementModel> get users => _users;

  void addUser(UserManagementModel user) {
    _users.add(user);
    notifyListeners();
  }

  void updateUser(String id, UserManagementModel updatedUser) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((user) => user.id == id);
    notifyListeners();
  }
}