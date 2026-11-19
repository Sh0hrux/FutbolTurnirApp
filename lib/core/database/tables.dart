import 'package:drift/drift.dart';

class Tournaments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get status => text()(); // 'active', 'completed', 'archived'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  TextColumn get logoPath => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get tournamentId => text().references(Tournaments, #id)();
  IntColumn get round => integer()();
  IntColumn get slotIndex => integer()();
  TextColumn get timeSlot => text()();
  @ReferenceName('homeMatches')
  TextColumn get homeTeamId => text().references(Teams, #id)();
  @ReferenceName('awayMatches')
  TextColumn get awayTeamId => text().references(Teams, #id)();
  IntColumn get homeScore => integer().nullable()();
  IntColumn get awayScore => integer().nullable()();
  TextColumn get status => text()(); // 'upcoming', 'live', 'finished'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoundRests extends Table {
  TextColumn get id => text()();
  TextColumn get tournamentId => text().references(Tournaments, #id)();
  IntColumn get round => integer()();
  TextColumn get teamId => text().references(Teams, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
