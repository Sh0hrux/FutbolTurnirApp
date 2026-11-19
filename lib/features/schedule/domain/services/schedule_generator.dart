import 'dart:math';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../teams/domain/entities/team_entity.dart';
import '../entities/match_entity.dart';
import '../entities/round_rest_entity.dart';

class ScheduleGenerationResult {
  final List<MatchEntity> matches;
  final TeamEntity? restingTeam;

  const ScheduleGenerationResult({
    required this.matches,
    this.restingTeam,
  });
}

class ScheduleGenerator {
  /// Generates matches and determines the resting team for a specific target round
  static ScheduleGenerationResult generateRound({
    required String tournamentId,
    required int targetRound,
    required List<TeamEntity> teams,
    required List<MatchEntity> existingMatches,
    required List<RoundRestEntity> existingRests,
    List<String>? timeSlots,
    int? randomSeed,
  }) {
    final slots = timeSlots ?? AppConstants.defaultTimeSlots;
    final random = Random(randomSeed);

    if (teams.length < 2) {
      return const ScheduleGenerationResult(matches: []);
    }

    // Step 1: Select Resting Team if teams count is odd
    TeamEntity? restingTeam;
    List<TeamEntity> playingTeams = List.from(teams);

    if (teams.length.isOdd) {
      restingTeam = _selectFairRestingTeam(
        teams: teams,
        existingRests: existingRests,
        targetRound: targetRound,
        random: random,
      );
      playingTeams.removeWhere((t) => t.id == restingTeam!.id);
    }

    // Step 2: Fair Match Pairing (avoid repeats, balance opponents)
    final pairings = _createFairPairings(
      playingTeams: playingTeams,
      existingMatches: existingMatches,
      random: random,
    );

    // Step 3: Fair Time Slot Assignment (avoid consecutive identical slots, balance slot usage)
    final assignedMatches = _assignFairTimeSlots(
      tournamentId: tournamentId,
      targetRound: targetRound,
      pairings: pairings,
      existingMatches: existingMatches,
      timeSlots: slots,
      random: random,
    );

    return ScheduleGenerationResult(
      matches: assignedMatches,
      restingTeam: restingTeam,
    );
  }

  /// Selects the fairest resting team among those who have rested the fewest times
  static TeamEntity _selectFairRestingTeam({
    required List<TeamEntity> teams,
    required List<RoundRestEntity> existingRests,
    required int targetRound,
    required Random random,
  }) {
    // Count previous rests per team
    final restCounts = <String, int>{for (var t in teams) t.id: 0};
    String? lastRoundRestedTeamId;

    for (final rest in existingRests) {
      restCounts[rest.teamId] = (restCounts[rest.teamId] ?? 0) + 1;
      if (rest.round == targetRound - 1) {
        lastRoundRestedTeamId = rest.teamId;
      }
    }

    // Find the minimum rest count among all teams
    int minRest = restCounts.values.reduce(min);

    // Filter candidates with minimum rest
    var candidates = teams.where((t) => restCounts[t.id] == minRest).toList();

    // Avoid having the same team rest two rounds in a row if multiple candidates exist
    if (candidates.length > 1 && lastRoundRestedTeamId != null) {
      final filtered = candidates.where((t) => t.id != lastRoundRestedTeamId).toList();
      if (filtered.isNotEmpty) {
        candidates = filtered;
      }
    }

    // Pick randomly among the fair candidates
    candidates.shuffle(random);
    return candidates.first;
  }

  /// Creates fair pairings among playing teams minimizing repeat matchups
  static List<_MatchPair> _createFairPairings({
    required List<TeamEntity> playingTeams,
    required List<MatchEntity> existingMatches,
    required Random random,
  }) {
    final matchCount = <String, int>{};
    final homeCount = <String, int>{for (var t in playingTeams) t.id: 0};
    final awayCount = <String, int>{for (var t in playingTeams) t.id: 0};

    // Build history of matchups and home/away counts
    for (final m in existingMatches) {
      final key = _pairKey(m.homeTeamId, m.awayTeamId);
      matchCount[key] = (matchCount[key] ?? 0) + 1;

      homeCount[m.homeTeamId] = (homeCount[m.homeTeamId] ?? 0) + 1;
      awayCount[m.awayTeamId] = (awayCount[m.awayTeamId] ?? 0) + 1;
    }

    // Backtracking to find a valid partition of playingTeams into n/2 pairs
    // with minimum repeat score
    List<TeamEntity> pool = List.from(playingTeams)..shuffle(random);
    final bestPairs = _findOptimalPairings(
      pool: pool,
      matchCount: matchCount,
      random: random,
    );

    // Determine home vs away for each pair
    final result = <_MatchPair>[];
    for (final pair in bestPairs) {
      final t1 = pair.$1;
      final t2 = pair.$2;

      final h1 = homeCount[t1.id] ?? 0;
      final h2 = homeCount[t2.id] ?? 0;

      // The team with fewer home games gets to be home team
      if (h1 < h2) {
        result.add(_MatchPair(homeTeam: t1, awayTeam: t2));
      } else if (h2 < h1) {
        result.add(_MatchPair(homeTeam: t2, awayTeam: t1));
      } else {
        // Random if tied
        if (random.nextBool()) {
          result.add(_MatchPair(homeTeam: t1, awayTeam: t2));
        } else {
          result.add(_MatchPair(homeTeam: t2, awayTeam: t1));
        }
      }
    }

    return result;
  }

  static List<(TeamEntity, TeamEntity)> _findOptimalPairings({
    required List<TeamEntity> pool,
    required Map<String, int> matchCount,
    required Random random,
  }) {
    List<(TeamEntity, TeamEntity)> current = [];
    List<(TeamEntity, TeamEntity)>? bestResult;
    int bestCost = 999999;

    void backtrack(List<TeamEntity> remaining, int currentCost) {
      if (remaining.isEmpty) {
        if (currentCost < bestCost) {
          bestCost = currentCost;
          bestResult = List.from(current);
        }
        return;
      }

      if (currentCost >= bestCost) return;

      final first = remaining.first;
      final candidates = remaining.sublist(1)..shuffle(random);

      // Sort candidate opponents by repeat matchup count
      candidates.sort((a, b) {
        final cA = matchCount[_pairKey(first.id, a.id)] ?? 0;
        final cB = matchCount[_pairKey(first.id, b.id)] ?? 0;
        return cA.compareTo(cB);
      });

      for (final other in candidates) {
        final pairCost = (matchCount[_pairKey(first.id, other.id)] ?? 0) * 1000;
        current.add((first, other));
        final nextRemaining = List<TeamEntity>.from(remaining)..remove(first)..remove(other);

        backtrack(nextRemaining, currentCost + pairCost);
        current.removeLast();

        // If we found a 0 cost pairing (no repeats anywhere), we can terminate early
        if (bestCost == 0) return;
      }
    }

    backtrack(pool, 0);
    return bestResult ?? [];
  }

  /// Assigns time slots fairly:
  /// - Avoids consecutive same slot for any team
  /// - Minimizes slot usage difference across slots
  static List<MatchEntity> _assignFairTimeSlots({
    required String tournamentId,
    required int targetRound,
    required List<_MatchPair> pairings,
    required List<MatchEntity> existingMatches,
    required List<String> timeSlots,
    required Random random,
  }) {
    final numSlots = timeSlots.length;
    final numMatches = pairings.length;

    // Track slot usage: teamId -> slotIndex -> count
    final teamSlotUsage = <String, List<int>>{};
    final lastRoundSlot = <String, int>{};

    for (final m in existingMatches) {
      teamSlotUsage.putIfAbsent(m.homeTeamId, () => List.filled(numSlots, 0));
      teamSlotUsage.putIfAbsent(m.awayTeamId, () => List.filled(numSlots, 0));

      if (m.slotIndex < numSlots) {
        teamSlotUsage[m.homeTeamId]![m.slotIndex] += 1;
        teamSlotUsage[m.awayTeamId]![m.slotIndex] += 1;
      }

      if (m.round == targetRound - 1) {
        lastRoundSlot[m.homeTeamId] = m.slotIndex;
        lastRoundSlot[m.awayTeamId] = m.slotIndex;
      }
    }

    // Cost function for match pair at slotIndex
    int calculateCost(_MatchPair pair, int slotIndex) {
      int cost = 0;
      final t1 = pair.homeTeam.id;
      final t2 = pair.awayTeam.id;

      final u1 = teamSlotUsage[t1]?[slotIndex] ?? 0;
      final u2 = teamSlotUsage[t2]?[slotIndex] ?? 0;

      // Base usage penalty
      cost += (u1 + u2) * 150;

      // Consecutive slot penalty: very high if team played in this exact slot in previous round
      if (lastRoundSlot[t1] == slotIndex) cost += 4000;
      if (lastRoundSlot[t2] == slotIndex) cost += 4000;

      // Variance penalty: penalize if usage in this slot is higher than team's minimum
      final min1 = teamSlotUsage[t1] == null ? 0 : teamSlotUsage[t1]!.reduce(min);
      final min2 = teamSlotUsage[t2] == null ? 0 : teamSlotUsage[t2]!.reduce(min);
      cost += (u1 - min1) * 300;
      cost += (u2 - min2) * 300;

      return cost;
    }

    // Find best permutation of slot indices for pairings
    // When numMatches <= numSlots (e.g. 5 matches, 5 slots)
    final availableSlots = List.generate(numSlots, (i) => i);

    List<int> bestSlotAssignment = List.generate(numMatches, (i) => i % numSlots);
    int bestTotalCost = 99999999;

    // Generate permutations
    final perms = _generatePermutations(availableSlots.sublist(0, min(numMatches, numSlots)));
    perms.shuffle(random);

    for (final perm in perms) {
      int totalCost = 0;
      for (int i = 0; i < numMatches; i++) {
        final slotIdx = perm[i % perm.length];
        totalCost += calculateCost(pairings[i], slotIdx);
      }

      if (totalCost < bestTotalCost) {
        bestTotalCost = totalCost;
        bestSlotAssignment = perm;
      }
    }

    // Construct MatchEntity list
    final now = DateTime.now();
    final result = <MatchEntity>[];

    for (int i = 0; i < numMatches; i++) {
      final slotIndex = bestSlotAssignment[i];
      final timeSlot = timeSlots[slotIndex % numSlots];
      final pair = pairings[i];

      result.add(
        MatchEntity(
          id: const Uuid().v4(),
          tournamentId: tournamentId,
          round: targetRound,
          slotIndex: slotIndex,
          timeSlot: timeSlot,
          homeTeamId: pair.homeTeam.id,
          awayTeamId: pair.awayTeam.id,
          status: MatchStatus.upcoming,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Sort by slot index so matches appear chronologically
    result.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return result;
  }

  static List<List<int>> _generatePermutations(List<int> list) {
    if (list.length <= 1) return [list];
    final result = <List<int>>[];
    for (int i = 0; i < list.length; i++) {
      final current = list[i];
      final remaining = List<int>.from(list)..removeAt(i);
      for (final perm in _generatePermutations(remaining)) {
        result.add([current, ...perm]);
      }
    }
    return result;
  }

  static String _pairKey(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? '$id1:$id2' : '$id2:$id1';
  }
}

class _MatchPair {
  final TeamEntity homeTeam;
  final TeamEntity awayTeam;

  const _MatchPair({
    required this.homeTeam,
    required this.awayTeam,
  });
}
