import 'team_model.dart';

class Tournament {
  final int id;
  final String name;
  final String game;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<int> teams;
  final List<Team>? teamsDetails;
  final String createdAt;

  Tournament({
    required this.id,
    required this.name,
    required this.game,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.teams,
    this.teamsDetails,
    required this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      game: json['game'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      teams: List<int>.from(json['teams'] ?? []),
      teamsDetails: json['teams_details'] != null
          ? (json['teams_details'] as List).map((i) => Team.fromJson(i)).toList()
          : null,
      createdAt: json['created_at'],
    );
  }
}

class Match {
  final int id;
  final int tournament;
  final String tournamentName;
  final int team1;
  final Team? team1Details;
  final int team2;
  final Team? team2Details;
  final int score1;
  final int score2;
  final int? winner;
  final Team? winnerDetails;
  final DateTime scheduledTime;
  final bool isCompleted;

  Match({
    required this.id,
    required this.tournament,
    required this.tournamentName,
    required this.team1,
    this.team1Details,
    required this.team2,
    this.team2Details,
    required this.score1,
    required this.score2,
    this.winner,
    this.winnerDetails,
    required this.scheduledTime,
    required this.isCompleted,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      tournament: json['tournament'],
      tournamentName: json['tournament_name'] ?? '',
      team1: json['team1'],
      team1Details: json['team1_details'] != null ? Team.fromJson(json['team1_details']) : null,
      team2: json['team2'],
      team2Details: json['team2_details'] != null ? Team.fromJson(json['team2_details']) : null,
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      winner: json['winner'],
      winnerDetails: json['winner_details'] != null ? Team.fromJson(json['winner_details']) : null,
      scheduledTime: DateTime.parse(json['scheduled_time']),
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
