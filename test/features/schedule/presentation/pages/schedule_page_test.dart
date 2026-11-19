import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/constants/app_strings.dart';
import 'package:football_tournament_manager/core/theme/app_theme.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/schedule/domain/entities/match_entity.dart';
import 'package:football_tournament_manager/features/schedule/domain/repositories/match_repository.dart';
import 'package:football_tournament_manager/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:football_tournament_manager/features/schedule/presentation/pages/schedule_page.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockMatchRepository mockMatchRepo;
  late MockTeamRepository mockTeamRepo;

  final now = DateTime.now();
  final teams = [
    TeamEntity(id: 't1', name: 'Arsenal', colorValue: 0xFFE53935, createdAt: now, updatedAt: now),
    TeamEntity(id: 't2', name: 'Liverpool', colorValue: 0xFFC8102E, createdAt: now, updatedAt: now),
    TeamEntity(id: 't3', name: 'Nasaf', colorValue: 0xFF003399, createdAt: now, updatedAt: now),
    TeamEntity(id: 't4', name: 'Navbahor', colorValue: 0xFF008000, createdAt: now, updatedAt: now),
  ];

  final matches = [
    MatchEntity(
      id: 'm1',
      tournamentId: 'tour-1',
      round: 1,
      slotIndex: 0,
      timeSlot: '17:00 – 18:00',
      homeTeamId: 't1',
      awayTeamId: 't2',
      status: MatchStatus.finished,
      homeScore: 2,
      awayScore: 1,
      createdAt: now,
      updatedAt: now,
    ),
    MatchEntity(
      id: 'm2',
      tournamentId: 'tour-1',
      round: 2,
      slotIndex: 0,
      timeSlot: '17:00 – 18:00',
      homeTeamId: 't3',
      awayTeamId: 't4',
      status: MatchStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    ),
    MatchEntity(
      id: 'm9',
      tournamentId: 'tour-1',
      round: 9,
      slotIndex: 0,
      timeSlot: '17:00 – 18:00',
      homeTeamId: 't1',
      awayTeamId: 't3',
      status: MatchStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  setUp(() {
    mockMatchRepo = MockMatchRepository();
    mockTeamRepo = MockTeamRepository();

    when(() => mockTeamRepo.getTeams(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => Right(teams));
    when(() => mockMatchRepo.getMatches(tournamentId: any(named: 'tournamentId')))
        .thenAnswer((_) async => Right(matches));
    when(() => mockMatchRepo.getRoundRests(tournamentId: any(named: 'tournamentId')))
        .thenAnswer((_) async => const Right([]));

  });

  void setupScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createWidgetUnderTest() {
    final bloc = ScheduleBloc(
      matchRepository: mockMatchRepo,
      teamRepository: mockTeamRepo,
    );

    return BlocProvider<ScheduleBloc>.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SchedulePage(),
        ),
      ),
    );
  }

  testWidgets('SchedulePage displays round chips and PageView for matches', (tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify chips for available rounds (1, 2, 9)
    expect(find.text('1-tur'), findsOneWidget);
    expect(find.text('2-tur'), findsOneWidget);

    // Verify PageView is present
    expect(find.byType(PageView), findsOneWidget);

    // Verify 1-tur matches count header
    expect(find.text('1-tur o‘yinlari (1 ta o‘yin)'), findsOneWidget);
  });

  testWidgets('SchedulePage tapping round chip animates PageView to selected round', (tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap on 2-tur chip
    await tester.tap(find.text('2-tur'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Should now display 2-tur matches count header
    expect(find.text('2-tur o‘yinlari (1 ta o‘yin)'), findsOneWidget);
  });

  testWidgets('SchedulePage displays delete round button and opens confirmation dialog', (tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify delete round icon button is present
    expect(find.byIcon(Icons.delete_sweep_outlined), findsWidgets);

    // Tap delete round icon button
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined).first);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('1-turni o‘chirish'), findsOneWidget);
    expect(find.text(AppStrings.cancel), findsOneWidget);
    expect(find.text(AppStrings.delete), findsOneWidget);
  });
}
