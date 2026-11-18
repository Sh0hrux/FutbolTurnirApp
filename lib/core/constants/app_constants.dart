class AppConstants {
  /// Default tournament ID
  static const String defaultTournamentId = 'tournament-primary-2026';
  static const String defaultTournamentName = 'Superliga 2026';

  /// Standard time slots for matches
  static const List<String> defaultTimeSlots = [
    '17:00 – 18:00',
    '18:00 – 19:00',
    '20:00 – 21:00',
    '21:00 – 22:00',
    '22:00 – 23:00',
  ];

  /// Default number of rounds for the tournament (full double round-robin for 12 teams)
  static const int defaultTotalRounds = 22;

  /// Initial 12 La Liga teams
  static const List<InitialTeamData> initialTeams = [
    InitialTeamData(name: 'Real Madrid', colorValue: 0xFF1565C0), // Blue
    InitialTeamData(name: 'Barcelona', colorValue: 0xFFE53935), // Red
    InitialTeamData(
      name: 'Atletico Madrid',
      colorValue: 0xFFC62828,
    ), // Dark Red
    InitialTeamData(name: 'Athletic Bilbao', colorValue: 0xFFD32F2F), // Red
    InitialTeamData(name: 'Sevilla', colorValue: 0xFFF44336), // Red
    InitialTeamData(name: 'Villarreal', colorValue: 0xFFFFEB3B), // Yellow
    InitialTeamData(name: 'Real Sociedad', colorValue: 0xFF1E88E5), // Blue
    InitialTeamData(name: 'Valencia', colorValue: 0xFFFB8C00), // Orange
    InitialTeamData(name: 'Real Betis', colorValue: 0xFF2E7D32), // Green
    InitialTeamData(name: 'Celta Vigo', colorValue: 0xFF00ACC1), // Cyan
    InitialTeamData(name: 'Girona', colorValue: 0xFFE53935), // Red
    InitialTeamData(name: 'Mallorca', colorValue: 0xFF6D4C41), // Brown
  ];

  /// Palette colors for team color picker
  static const List<int> presetTeamColors = [
    0xFFE53935, // Red
    0xFFC62828, // Dark Red
    0xFF1E88E5, // Blue
    0xFF1565C0, // Navy
    0xFF00C853, // Pitch Green
    0xFF2E7D32, // Forest Green
    0xFFFFB300, // Amber
    0xFFFB8C00, // Orange
    0xFF8E24AA, // Violet
    0xFF6A1B9A, // Deep Purple
    0xFF00897B, // Teal
    0xFF00ACC1, // Cyan
    0xFF546E7A, // Blue Grey
    0xFFFDD835, // Yellow
  ];
}

class InitialTeamData {
  final String name;
  final int colorValue;

  const InitialTeamData({required this.name, required this.colorValue});
}
