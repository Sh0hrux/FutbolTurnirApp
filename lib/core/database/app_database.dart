import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../features/schedule/domain/entities/match_entity.dart';
import '../../features/schedule/domain/entities/round_rest_entity.dart';
import '../../features/schedule/domain/services/schedule_generator.dart';
import '../../features/teams/domain/entities/team_entity.dart';
import '../constants/app_constants.dart';
import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tournaments, Teams, Matches, RoundRests])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openAppConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await seedInitialDataIfEmpty();
    },
  );

  // ================= TEAMS QUERIES =================

  /// Get all active teams (or all including archived if includeArchived is true)
  Future<List<Team>> getAllTeams({bool includeArchived = false}) {
    if (includeArchived) {
      return (select(
        teams,
      )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    }
    return (select(teams)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Watch active teams stream
  Stream<List<Team>> watchActiveTeams() {
    return (select(teams)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Get single team by ID
  Future<Team?> getTeamById(String id) {
    return (select(teams)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert new team
  Future<int> insertTeam(TeamsCompanion entry) {
    return into(teams).insert(entry);
  }

  /// Update team
  Future<bool> updateTeam(Team team) {
    return update(teams).replace(team);
  }

  /// Check if a team has any matches recorded
  Future<bool> hasTeamPlayedAnyMatch(String teamId) async {
    final query = select(matches)
      ..where((m) => m.homeTeamId.equals(teamId) | m.awayTeamId.equals(teamId));
    final count = await query.get();
    return count.isNotEmpty;
  }

  /// Archive team
  Future<int> archiveTeam(String teamId) {
    return (update(teams)..where((t) => t.id.equals(teamId))).write(
      TeamsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Unarchive team
  Future<int> unarchiveTeam(String teamId) {
    return (update(teams)..where((t) => t.id.equals(teamId))).write(
      TeamsCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete team permanently (only if no matches exist)
  Future<int> deleteTeamPermanently(String teamId) {
    return (delete(teams)..where((t) => t.id.equals(teamId))).go();
  }

  // ================= MATCHES QUERIES =================

  /// Get all matches for tournament
  Future<List<Matche>> getMatchesForTournament(String tournamentId) {
    return (select(matches)
          ..where((m) => m.tournamentId.equals(tournamentId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.round),
            (m) => OrderingTerm(expression: m.slotIndex),
          ]))
        .get();
  }

  /// Watch matches for tournament
  Stream<List<Matche>> watchMatchesForTournament(String tournamentId) {
    return (select(matches)
          ..where((m) => m.tournamentId.equals(tournamentId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.round),
            (m) => OrderingTerm(expression: m.slotIndex),
          ]))
        .watch();
  }

  /// Get matches for a specific round
  Future<List<Matche>> getMatchesByRound(String tournamentId, int round) {
    return (select(matches)
          ..where(
            (m) => m.tournamentId.equals(tournamentId) & m.round.equals(round),
          )
          ..orderBy([(m) => OrderingTerm(expression: m.slotIndex)]))
        .get();
  }

  /// Insert matches in transaction
  Future<void> insertMatchesBatch(List<MatchesCompanion> entries) async {
    await batch((b) {
      b.insertAll(matches, entries);
    });
  }

  /// Update match result (score and status)
  Future<int> updateMatchResult({
    required String matchId,
    required int? homeScore,
    required int? awayScore,
    required String status,
  }) {
    return (update(matches)..where((m) => m.id.equals(matchId))).write(
      MatchesCompanion(
        homeScore: Value(homeScore),
        awayScore: Value(awayScore),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update match time slot
  Future<int> updateMatchTimeSlot({
    required String matchId,
    required String newTimeSlot,
    required int newSlotIndex,
  }) {
    return (update(matches)..where((m) => m.id.equals(matchId))).write(
      MatchesCompanion(
        timeSlot: Value(newTimeSlot),
        slotIndex: Value(newSlotIndex),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete match
  Future<int> deleteMatch(String matchId) {
    return (delete(matches)..where((m) => m.id.equals(matchId))).go();
  }

  /// Delete upcoming matches for a round (for randomize/regenerate)
  Future<int> deleteUpcomingMatchesForRound(String tournamentId, int round) {
    return (delete(matches)..where(
          (m) =>
              m.tournamentId.equals(tournamentId) &
              m.round.equals(round) &
              m.status.equals('upcoming'),
        ))
        .go();
  }

  /// Delete an entire round (all matches and round rest for that round)
  Future<void> deleteEntireRound(String tournamentId, int round) async {
    await transaction(() async {
      await (delete(matches)..where(
            (m) => m.tournamentId.equals(tournamentId) & m.round.equals(round),
          ))
          .go();
      await (delete(roundRests)..where(
            (r) => r.tournamentId.equals(tournamentId) & r.round.equals(round),
          ))
          .go();
    });
  }

  // ================= ROUND RESTS QUERIES =================

  /// Get resting team for round
  Future<RoundRest?> getRestForRound(String tournamentId, int round) {
    return (select(roundRests)..where(
          (r) => r.tournamentId.equals(tournamentId) & r.round.equals(round),
        ))
        .getSingleOrNull();
  }

  /// Get all round rests for tournament
  Future<List<RoundRest>> getAllRests(String tournamentId) {
    return (select(roundRests)
          ..where((r) => r.tournamentId.equals(tournamentId))
          ..orderBy([(r) => OrderingTerm(expression: r.round)]))
        .get();
  }

  /// Insert round rest
  Future<int> insertRoundRest(RoundRestsCompanion entry) {
    return into(roundRests).insert(entry);
  }

  /// Delete round rest for a round
  Future<int> deleteRoundRest(String tournamentId, int round) {
    return (delete(roundRests)..where(
          (r) => r.tournamentId.equals(tournamentId) & r.round.equals(round),
        ))
        .go();
  }

  // ================= TOURNAMENT RESET & MANAGEMENT =================

  /// Seed initial tournament, 12 La Liga teams and 22 rounds schedule if empty
  Future<void> seedInitialDataIfEmpty() async {
    final tournamentId = AppConstants.defaultTournamentId;
    final now = DateTime.now();

    final existingTourney = await getTournament(tournamentId);
    if (existingTourney == null) {
      await into(tournaments).insert(
        TournamentsCompanion.insert(
          id: tournamentId,
          name: AppConstants.defaultTournamentName,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final existingTeams = await getAllTeams(includeArchived: true);
    const legacyTeamNames = {
      'Шохгузар ФК',
      'Булокбоши ФК',
      'Фахрийлар ФК',
      'Дустлик ФК',
      'Курғонча ФК',
      'Арсенал ФК',
      'Сарбонтепа ФК',
      'Махалла ФК',
      'Ливерпуль ФК',
      'Найман ФК',
      'Кезар ФК',
      'Paxtakor',
      'Bunyodkor',
      'Do‘stlik',
      'Shoxguzar',
    };
    final hasLegacyTeams =
        existingTeams.isNotEmpty &&
        existingTeams.every((team) => legacyTeamNames.contains(team.name));

    if (existingTeams.isEmpty || hasLegacyTeams) {
      await transaction(() async {
        if (hasLegacyTeams) {
          await (delete(
            matches,
          )..where((m) => m.tournamentId.equals(tournamentId))).go();
          await (delete(
            roundRests,
          )..where((r) => r.tournamentId.equals(tournamentId))).go();
          await delete(teams).go();
        }
        for (final teamData in AppConstants.initialTeams) {
          await into(teams).insert(
            TeamsCompanion.insert(
              id: const Uuid().v4(),
              name: teamData.name,
              colorValue: teamData.colorValue,
              isArchived: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
    }

    final existingMatches = await (select(
      matches,
    )..where((m) => m.tournamentId.equals(tournamentId))).get();
    if (existingMatches.isEmpty) {
      await _seedScheduleForTeams(tournamentId);
    }
  }

  /// Automatically generate and persist 22 rounds schedule for all active teams
  Future<void> _seedScheduleForTeams(String tournamentId) async {
    final activeTeams = await getAllTeams(includeArchived: false);
    if (activeTeams.length < 2) return;

    final teamEntities = activeTeams
        .map(
          (t) => TeamEntity(
            id: t.id,
            name: t.name,
            colorValue: t.colorValue,
            logoPath: t.logoPath,
            isArchived: t.isArchived,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
          ),
        )
        .toList();

    final now = DateTime.now();
    final accumulatedMatches = <MatchEntity>[];
    final accumulatedRests = <RoundRestEntity>[];

    await transaction(() async {
      for (int round = 1; round <= AppConstants.defaultTotalRounds; round++) {
        final roundResult = ScheduleGenerator.generateRound(
          tournamentId: tournamentId,
          targetRound: round,
          teams: teamEntities,
          existingMatches: accumulatedMatches,
          existingRests: accumulatedRests,
          randomSeed: 2026 + round,
        );

        for (final m in roundResult.matches) {
          await into(matches).insert(
            MatchesCompanion.insert(
              id: m.id,
              tournamentId: m.tournamentId,
              round: m.round,
              slotIndex: m.slotIndex,
              timeSlot: m.timeSlot,
              homeTeamId: m.homeTeamId,
              awayTeamId: m.awayTeamId,
              status: m.status.name,
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
            ),
          );
          accumulatedMatches.add(m);
        }

        if (roundResult.restingTeam != null) {
          final rest = RoundRestEntity(
            id: const Uuid().v4(),
            tournamentId: tournamentId,
            round: round,
            teamId: roundResult.restingTeam!.id,
            createdAt: now,
          );
          await into(roundRests).insert(
            RoundRestsCompanion.insert(
              id: rest.id,
              tournamentId: rest.tournamentId,
              round: rest.round,
              teamId: rest.teamId,
              createdAt: rest.createdAt,
            ),
          );
          accumulatedRests.add(rest);
        }
      }
    });
  }

  /// Reset current tournament (clears all matches and round rests, restores active state, and regenerates default 22 rounds)
  Future<void> resetTournament(String tournamentId) async {
    await transaction(() async {
      await (delete(
        matches,
      )..where((m) => m.tournamentId.equals(tournamentId))).go();
      await (delete(
        roundRests,
      )..where((r) => r.tournamentId.equals(tournamentId))).go();
      await (update(
        tournaments,
      )..where((t) => t.id.equals(tournamentId))).write(
        TournamentsCompanion(
          status: const Value('active'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
    await _seedScheduleForTeams(tournamentId);
  }

  /// Get current tournament
  Future<Tournament?> getTournament(String tournamentId) {
    return (select(
      tournaments,
    )..where((t) => t.id.equals(tournamentId))).getSingleOrNull();
  }

  /// Update tournament status
  Future<int> updateTournamentStatus(String tournamentId, String status) {
    return (update(tournaments)..where((t) => t.id.equals(tournamentId))).write(
      TournamentsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
