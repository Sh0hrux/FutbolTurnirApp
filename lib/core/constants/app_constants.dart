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

  /// Default number of rounds for the tournament (full double round-robin for 11 teams)
  static const int defaultTotalRounds = 22;

  /// Initial 11 default teams as requested in the requirements (in Cyrillic)
  static const List<InitialTeamData> initialTeams = [
    InitialTeamData(name: 'Шохгузар ФК', colorValue: 0xFF00897B),   // Teal
    InitialTeamData(name: 'Булокбоши ФК', colorValue: 0xFF00C853),  // Pitch Green
    InitialTeamData(name: 'Фахрийлар ФК', colorValue: 0xFFFFB300),  // Amber/Gold
    InitialTeamData(name: 'Дустлик ФК', colorValue: 0xFF1E88E5),    // Blue
    InitialTeamData(name: 'Курғонча ФК', colorValue: 0xFFFB8C00),   // Orange
    InitialTeamData(name: 'Арсенал ФК', colorValue: 0xFFE53935),    // Red
    InitialTeamData(name: 'Сарбонтепа ФК', colorValue: 0xFF1565C0), // Navy
    InitialTeamData(name: 'Махалла ФК', colorValue: 0xFF2E7D32),    // Forest Green
    InitialTeamData(name: 'Ливерпуль ФК', colorValue: 0xFFC62828),  // Dark Red
    InitialTeamData(name: 'Найман ФК', colorValue: 0xFF8E24AA),     // Purple
    InitialTeamData(name: 'Кезар ФК', colorValue: 0xFF00ACC1),      // Cyan
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

  const InitialTeamData({
    required this.name,
    required this.colorValue,
  });
}

