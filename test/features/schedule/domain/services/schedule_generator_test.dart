import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/match_entity.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/round_rest_entity.dart';
import 'package:football_tournament_manager/features/schedule/domain/services/schedule_generator.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';

void main() {
  group('ScheduleGenerator', () {
    final now = DateTime.now();

    // 11 sample teams as requested in requirements
    final elevenTeams = List.generate(
      11,
      (i) => TeamEntity(
        id: 'team-$i',
        name: 'Team $i',
        colorValue: 0xFF000000 + (i * 0x111111),
        createdAt: now,
        updatedAt: now,
      ),
    );

    test('11 teams 10 rounds: fair distribution, no duplicate play in same round', () {
      final allMatches = <MatchEntity>[];
      final allRests = <RoundRestEntity>[];

      // Slot usage tracking: teamId -> slotIndex -> count
      final teamSlotCounts = <String, Map<int, int>>{};
      for (final t in elevenTeams) {
        teamSlotCounts[t.id] = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
      }

      // Rest counts: teamId -> count
      final teamRestCounts = <String, int>{for (var t in elevenTeams) t.id: 0};

      // Consecutive slot violation tracker
      int consecutiveSlotViolations = 0;

      for (int round = 1; round <= 10; round++) {
        final result = ScheduleGenerator.generateRound(
          tournamentId: 't1',
          targetRound: round,
          teams: elevenTeams,
          existingMatches: allMatches,
          existingRests: allRests,
          randomSeed: 42 + round,
        );

        // 1. Exactly 5 matches per round
        expect(result.matches.length, 5, reason: 'Round $round should have 5 matches');

        // 2. Exactly 1 resting team per round
        expect(result.restingTeam, isNotNull, reason: 'Round $round should have 1 resting team');
        teamRestCounts[result.restingTeam!.id] = teamRestCounts[result.restingTeam!.id]! + 1;

        allRests.add(
          RoundRestEntity(
            id: 'rest-$round',
            tournamentId: 't1',
            round: round,
            teamId: result.restingTeam!.id,
            createdAt: now,
          ),
        );

        // 3. No team plays more than once in the same round (10 distinct teams)
        final teamsInRound = <String>{};
        for (final m in result.matches) {
          expect(teamsInRound.contains(m.homeTeamId), false,
              reason: 'Team ${m.homeTeamId} plays twice in round $round');
          expect(teamsInRound.contains(m.awayTeamId), false,
              reason: 'Team ${m.awayTeamId} plays twice in round $round');
          expect(m.homeTeamId != m.awayTeamId, true);
          expect(m.homeTeamId != result.restingTeam!.id, true);
          expect(m.awayTeamId != result.restingTeam!.id, true);

          teamsInRound.add(m.homeTeamId);
          teamsInRound.add(m.awayTeamId);

          // Check consecutive slot
          if (round > 1) {
            final prevRoundHomeMatch = allMatches
                .where((old) => old.round == round - 1 && (old.homeTeamId == m.homeTeamId || old.awayTeamId == m.homeTeamId))
                .firstOrNull;
            if (prevRoundHomeMatch != null && prevRoundHomeMatch.slotIndex == m.slotIndex) {
              consecutiveSlotViolations++;
            }

            final prevRoundAwayMatch = allMatches
                .where((old) => old.round == round - 1 && (old.homeTeamId == m.awayTeamId || old.awayTeamId == m.awayTeamId))
                .firstOrNull;
            if (prevRoundAwayMatch != null && prevRoundAwayMatch.slotIndex == m.slotIndex) {
              consecutiveSlotViolations++;
            }
          }

          // Accumulate slot usage
          teamSlotCounts[m.homeTeamId]![m.slotIndex] =
              (teamSlotCounts[m.homeTeamId]![m.slotIndex] ?? 0) + 1;
          teamSlotCounts[m.awayTeamId]![m.slotIndex] =
              (teamSlotCounts[m.awayTeamId]![m.slotIndex] ?? 0) + 1;
        }

        expect(teamsInRound.length, 10, reason: 'Exactly 10 teams must play in round $round');
        allMatches.addAll(result.matches);
      }

      // 4. Rest fairness: Difference in rest count between any two teams should not exceed 1
      final minRests = teamRestCounts.values.reduce(min);
      final maxRests = teamRestCounts.values.reduce(max);
      expect(maxRests - minRests <= 1, true,
          reason: 'Rest count difference ($maxRests vs $minRests) should not exceed 1');

      // 5. Consecutive slot violations should be 0 across all 10 rounds
      expect(consecutiveSlotViolations, 0,
          reason: 'Teams should not be assigned consecutive identical time slots');

      // 6. Time slot distribution fairness:
      // For each team, slot variance (max slot usage - min slot usage) should be very low (<= 2 across 10 rounds)
      for (final t in elevenTeams) {
        final slots = teamSlotCounts[t.id]!.values.toList();
        final maxSlot = slots.reduce(max);
        final minSlot = slots.reduce(min);
        expect(maxSlot - minSlot <= 2, true,
            reason: 'Team ${t.id} slot usage ($slots) variance should be <= 2');
      }
    });

    test('Even number of teams (10 teams): 0 resting teams, 5 matches per round', () {
      final tenTeams = elevenTeams.sublist(0, 10);
      final result = ScheduleGenerator.generateRound(
        tournamentId: 't1',
        targetRound: 1,
        teams: tenTeams,
        existingMatches: [],
        existingRests: [],
      );

      expect(result.matches.length, 5);
      expect(result.restingTeam, isNull);
    });

    test('Pairing uniqueness: avoids repeat matches when fresh opponents exist', () {
      final fourTeams = elevenTeams.sublist(0, 4);

      // Round 1
      final r1 = ScheduleGenerator.generateRound(
        tournamentId: 't1',
        targetRound: 1,
        teams: fourTeams,
        existingMatches: [],
        existingRests: [],
        randomSeed: 1,
      );

      // Round 2
      final r2 = ScheduleGenerator.generateRound(
        tournamentId: 't1',
        targetRound: 2,
        teams: fourTeams,
        existingMatches: r1.matches,
        existingRests: [],
        randomSeed: 2,
      );

      // In Round 2 with 4 teams, pairings should be distinct from Round 1 pairings
      final r1Pairs = r1.matches.map((m) => '${m.homeTeamId}:${m.awayTeamId}').toSet();
      final r1PairsRev = r1.matches.map((m) => '${m.awayTeamId}:${m.homeTeamId}').toSet();

      for (final m in r2.matches) {
        final key = '${m.homeTeamId}:${m.awayTeamId}';
        expect(r1Pairs.contains(key), false, reason: 'Round 2 should not repeat Round 1 pairing');
        expect(r1PairsRev.contains(key), false, reason: 'Round 2 should not repeat Round 1 pairing');
      }
    });

    test('11 teams 22 rounds: complete double round-robin, exactly 2 rests per team, 110 matches total', () {
      final allMatches = <MatchEntity>[];
      final allRests = <RoundRestEntity>[];
      final teamRestCounts = <String, int>{for (var t in elevenTeams) t.id: 0};

      for (int round = 1; round <= 22; round++) {
        final result = ScheduleGenerator.generateRound(
          tournamentId: 't1',
          targetRound: round,
          teams: elevenTeams,
          existingMatches: allMatches,
          existingRests: allRests,
          randomSeed: 100 + round,
        );

        expect(result.matches.length, 5);
        expect(result.restingTeam, isNotNull);
        teamRestCounts[result.restingTeam!.id] = teamRestCounts[result.restingTeam!.id]! + 1;

        allRests.add(
          RoundRestEntity(
            id: 'rest-$round',
            tournamentId: 't1',
            round: round,
            teamId: result.restingTeam!.id,
            createdAt: now,
          ),
        );
        allMatches.addAll(result.matches);
      }

      expect(allMatches.length, 110);
      expect(allRests.length, 22);

      // In 22 rounds with 11 teams, each team should rest exactly 2 times!
      for (final t in elevenTeams) {
        expect(teamRestCounts[t.id], 2);
      }
    });
  });
}
