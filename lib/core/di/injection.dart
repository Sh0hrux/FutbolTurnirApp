import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/schedule/data/datasources/match_local_data_source.dart';
import '../../features/schedule/data/datasources/match_remote_data_source.dart';
import '../../features/schedule/data/datasources/mock_match_remote_data_source.dart';
import '../../features/schedule/data/repositories/match_repository_impl.dart';
import '../../features/schedule/domain/repositories/match_repository.dart';
import '../../features/schedule/presentation/bloc/schedule_bloc.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/standings/data/repositories/standings_repository_impl.dart';
import '../../features/standings/domain/repositories/standings_repository.dart';
import '../../features/standings/presentation/bloc/standings_bloc.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';
import '../../features/teams/data/datasources/mock_team_remote_data_source.dart';
import '../../features/teams/data/datasources/team_local_data_source.dart';
import '../../features/teams/data/datasources/team_remote_data_source.dart';
import '../../features/teams/data/repositories/team_repository_impl.dart';
import '../../features/teams/domain/repositories/team_repository.dart';
import '../../features/teams/presentation/cubit/teams_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Database
  final database = AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => database);

  // Data Sources - Local
  sl.registerLazySingleton<TeamLocalDataSource>(
    () => TeamLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<MatchLocalDataSource>(
    () => MatchLocalDataSourceImpl(database: sl()),
  );

  // Data Sources - Remote (Mock or Real based on AppConfig.useMockApi)
  if (AppConfig.useMockApi) {
    sl.registerLazySingleton<TeamRemoteDataSource>(
      () => MockTeamRemoteDataSource(localDataSource: sl()),
    );
    sl.registerLazySingleton<MatchRemoteDataSource>(
      () => MockMatchRemoteDataSource(localDataSource: sl()),
    );
  } else {
    // When real remote REST API is connected in future
    sl.registerLazySingleton<TeamRemoteDataSource>(
      () => MockTeamRemoteDataSource(localDataSource: sl()),
    );
    sl.registerLazySingleton<MatchRemoteDataSource>(
      () => MockMatchRemoteDataSource(localDataSource: sl()),
    );
  }

  // Repositories
  sl.registerLazySingleton<TeamRepository>(
    () => TeamRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(
      remoteDataSource: sl(),
      teamRepository: sl(),
    ),
  );
  sl.registerLazySingleton<StandingsRepository>(
    () => StandingsRepositoryImpl(
      teamRepository: sl(),
      matchRepository: sl(),
    ),
  );

  // Blocs & Cubits
  sl.registerFactory<TeamsCubit>(
    () => TeamsCubit(
      repository: sl(),
      matchRepository: sl(),
      standingsRepository: sl(),
    ),
  );
  sl.registerFactory<ScheduleBloc>(
    () => ScheduleBloc(
      matchRepository: sl(),
      teamRepository: sl(),
    ),
  );
  sl.registerFactory<StandingsBloc>(
    () => StandingsBloc(repository: sl()),
  );
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      teamRepository: sl(),
      matchRepository: sl(),
      standingsRepository: sl(),
    ),
  );
  sl.registerFactory<StatisticsBloc>(
    () => StatisticsBloc(
      teamRepository: sl(),
      matchRepository: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(prefs: sl()),
  );
}
