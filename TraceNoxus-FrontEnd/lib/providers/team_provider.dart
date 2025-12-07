import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';

class TeamProvider with ChangeNotifier {
  final TeamService _teamService = TeamService();
  
  List<Team> _teams = [];
  Team? _currentTeam;
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => _teams;
  Team? get currentTeam => _currentTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teams = await _teamService.getTeams();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTeam(Team team) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTeam = await _teamService.createTeam(team.name, team.description);
      _teams.add(newTeam);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method to manually add a member to a team (for admin)
  // This might involve updating the user (via UserManagement) or an endpoint on Team.
  // Since our backend logic is "Update User's game -> Auto Assign", 
  // we might effectively just need to refresh the team list or team detail.
  
  Future<void> refreshTeam(String teamId) async {
      try {
          final updatedTeam = await _teamService.getTeam(teamId);
           final index = _teams.indexWhere((t) => t.id.toString() == teamId);
           if (index != -1) {
               _teams[index] = updatedTeam;
               if (_currentTeam?.id.toString() == teamId) {
                   _currentTeam = updatedTeam;
               }
               notifyListeners();
           }
      } catch (e) {
          print("Error refreshing team: $e");
      }
  }

  Future<void> deleteTeam(String id) async {
      _isLoading = true;
      notifyListeners();
      try {
          await _teamService.deleteTeam(id);
          _teams.removeWhere((t) => t.id.toString() == id);
          if (_currentTeam?.id.toString() == id) {
              _currentTeam = null;
          }
          notifyListeners();
      } catch (e) {
          _error = e.toString();
          notifyListeners();
          rethrow;
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }
}
