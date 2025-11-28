enum GamePlayed { valorant, mobileLegends, leagueOfLegends, tekken8 }

extension GamePlayedExtension on GamePlayed {
  String get displayName {
    switch (this) {
      case GamePlayed.valorant:
        return 'VALORANT';
      case GamePlayed.mobileLegends:
        return 'MOBILE LEGENDS';
      case GamePlayed.leagueOfLegends:
        return 'LEAGUE OF LEGENDS';
      case GamePlayed.tekken8:
        return 'TEKKEN 8';
    }
  }
}