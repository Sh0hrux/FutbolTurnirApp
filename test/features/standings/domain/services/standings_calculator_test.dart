import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/match_entity.dart';
import 'package:football_tournament_manager/features/standings/domain/services/standings_calculator.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';

void main() {
  group('StandingsCalculator', () {
    final now = DateTime.now();

    final teamA = TeamEntity(
      id: 'team-a',
      name: 'Arsenal',
      colorValue: 0xFFE53935,
      createdAt: now,
      updatedAt: now,
    );
    final teamB = TeamEntity(
      id: 'team-b',
      name: 'Liverpool',
      colorValue: 0xFFC62828,
      createdAt: now,
      updatedAt: now,
    );
    final teamC = TeamEntity(
      id: 'team-c',
      name: 'Chelsea',
      colorValue: 0xFF1E88E5,
      createdAt: now,
      updatedAt: now,
    );

    test('calculates correct points: win = 3, draw = 1, loss = 0', () {
      final matches = [
        // Arsenal 2 : 1 Liverpool
        MatchEntity(
          id: 'm1',
          tournamentId: 't1',
          round: 1,
          slotIndex: 0,
          timeSlot: '17:00 – 18:00',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          homeScore: 2,
          awayScore: 1,
          status: MatchStatus.finished,
          createdAt: now,
          updatedAt: now,
        ),
        // Chelsea 1 : 1 Arsenal
        MatchEntity(
          id: 'm2',
          tournamentId: 't1',
          round: 2,
          slotIndex: 1,
          timeSlot: '18:00 – 19:00',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          homeScore: 1,
          awayScore: 1,
          status: MatchStatus.finished,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final standings = StandingsCalculator.calculate(
        teams: [teamA, teamB, teamC],
        matches: matches,
      );

      // Arsenal: 1 win, 1 draw = 4 pts, GF: 3, GA: 2, GD: +1
      final arsenalRow = standings.firstWhere((r) => r.teamId == 'team-a');
      expect(arsenalRow.played, 2);
      expect(arsenalRow.won, 1);
      expect(arsenalRow.drawn, 1);
      expect(arsenalRow.lost, 0);
      expect(arsenalRow.points, 4);
      expect(arsenalRow.goalsFor, 3);
      expect(arsenalRow.goalsAgainst, 2);
      expect(arsenalRow.goalDifference, 1);

      // Chelsea: 1 draw = 1 pt
      final chelseaRow = standings.firstWhere((r) => r.teamId == 'team-c');
      expect(chelseaRow.played, 1);
      expect(chelseaRow.points, 1);

      // Liverpool: 1 loss = 0 pts
      final liverpoolRow = standings.firstWhere((r) => r.teamId == 'team-b');
      expect(liverpoolRow.played, 1);
      expect(liverpoolRow.points, 0);
    });

    test('ignores upcoming and live matches', () {
      final matches = [
        MatchEntity(
          id: 'm1',
          tournamentId: 't1',
          round: 1,
          slotIndex: 0,
          timeSlot: '17:00 – 18:00',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          homeScore: 3,
          awayScore: 0,
          status: MatchStatus.upcoming, // Upcoming, should be ignored
          createdAt: now,
          updatedAt: now,
        ),
        MatchEntity(
          id: 'm2',
          tournamentId: 't1',
          round: 1,
          slotIndex: 1,
          timeSlot: '18:00 – 19:00',
          homeTeamId: 'team-a',
          awayTeamId: 'team-c',
          homeScore: 2,
          awayScore: 0,
          status: MatchStatus.live, // Live, should be ignored
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final standings = StandingsCalculator.calculate(
        teams: [teamA, teamB, teamC],
        matches: matches,
      );

      for (final row in standings) {
        expect(row.played, 0);
        expect(row.points, 0);
      }
    });

    test('sorts by Points -> GD -> GF -> Head-to-Head', () {
      // Scenario: Team A and Team B both have 3 points.
      // Team A beat Team B 1-0 in direct match!
      // Therefore, Team A should be ranked #1 by Head-to-Head!
      final matches = [
        // Match 1: Team A 1 - 0 Team B (A wins direct match)
        MatchEntity(
          id: 'm1',
          tournamentId: 't1',
          round: 1,
          slotIndex: 0,
          timeSlot: '17:00 – 18:00',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          homeScore: 1,
          awayScore: 0,
          status: MatchStatus.finished,
          createdAt: now,
          updatedAt: now,
        ),
        // Match 2: Team B 2 - 1 Team C (B wins)
        MatchEntity(
          id: 'm2',
          tournamentId: 't1',
          round: 2,
          slotIndex: 0,
          timeSlot: '17:00 – 18:00',
          homeTeamId: 'team-b',
          awayTeamId: 'team-c',
          homeScore: 2,
          awayScore: 1,
          status: MatchStatus.finished,
          createdAt: now,
          updatedAt: now,
        ),
        // Match 3: Team C 1 - 0 Team A (C wins)
        MatchEntity(
          id: 'm3',
          tournamentId: 't1',
          round: 3,
          slotIndex: 0,
          timeSlot: '17:00 – 18:00',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          homeScore: 1,
          awayScore: 0,
          status: MatchStatus.finished,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Points:
      // Team A: beat B (3 pts), lost to C -> 3 pts, GD: 1-1=0, GF: 1
      // Team B: lost to A, beat C (3 pts) -> 3 pts, GD: 2-2=0, GF: 2
      // Team C: lost to B, beat A (3 pts) -> 3 pts, GD: 2-2=0, GF: 2
      // Here, Team B has GD 0 and GF 2, Team C has GD 0 and GF 2, Team A has GD 0 and GF 1.
      // Between Team B and Team C (both 3 pts, GD 0, GF 2), Team B beat Team C head-to-head (2-1)!
      final standings = StandingsCalculator.calculate(
        teams: [teamA, teamB, teamC],
        matches: matches,
      );

      expect(standings[0].teamId, 'team-b'); // Rank 1: 3 pts, GD 0, GF 2, beat C head-to-head
      expect(standings[1].teamId, 'team-c'); // Rank 2: 3 pts, GD 0, GF 2
      expect(standings[2].teamId, 'team-a'); // Rank 3: 3 pts, GD 0, GF 1
      expect(standings[0].pos, 1);
      expect(standings[1].pos, 2);
      expect(standings[2].pos, 3);
    });
  });
}
