import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/theme/app_theme.dart';
import 'package:football_tournament_manager/core/utils/either.dart';
import 'package:football_tournament_manager/features/standings/domain/entities/standing_row_entity.dart';
import 'package:football_tournament_manager/features/standings/domain/repositories/standings_repository.dart';
import 'package:football_tournament_manager/features/standings/presentation/bloc/standings_bloc.dart';
import 'package:football_tournament_manager/features/standings/presentation/pages/standings_page.dart';
import 'package:mocktail/mocktail.dart';

class MockStandingsRepository extends Mock implements StandingsRepository {}

void main() {
  late MockStandingsRepository mockRepo;

  final testStandings = [
    const StandingRowEntity(
      pos: 1,
      teamId: 'team-1',
      teamName: 'Arsenal',
      colorValue: 0xFFEF0107,
      played: 5,
      won: 4,
      drawn: 1,
      lost: 0,
      goalsFor: 12,
      goalsAgainst: 3,
      goalDifference: 9,
      points: 13,
    ),
    const StandingRowEntity(
      pos: 2,
      teamId: 'team-2',
      teamName: 'Liverpool',
      colorValue: 0xFFC8102E,
      played: 5,
      won: 3,
      drawn: 1,
      lost: 1,
      goalsFor: 10,
      goalsAgainst: 5,
      goalDifference: 5,
      points: 10,
    ),
    const StandingRowEntity(
      pos: 3,
      teamId: 'team-3',
      teamName: 'Nasaf',
      colorValue: 0xFF003399,
      played: 5,
      won: 3,
      drawn: 0,
      lost: 2,
      goalsFor: 8,
      goalsAgainst: 6,
      goalDifference: 2,
      points: 9,
    ),
  ];

  setUp(() {
    mockRepo = MockStandingsRepository();
    when(() => mockRepo.getStandings(tournamentId: any(named: 'tournamentId')))
        .thenAnswer((_) async => Right(testStandings));
  });

  Widget createWidgetUnderTest() {
    final bloc = StandingsBloc(repository: mockRepo);

    return BlocProvider<StandingsBloc>.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const StandingsPage(),
        ),
      ),
    );
  }

  void setupScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('StandingsPage renders exact columns: Pl, Team, G, Goals, +/-, Pts', (tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Sticky Header Columns matching the user image
    expect(find.text('Pl'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('+/-'), findsOneWidget);
    expect(find.text('Pts'), findsOneWidget);

    // Verify position format '1.', '2.', '3.'
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);

    // Verify team names
    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('Liverpool'), findsOneWidget);
    expect(find.text('Nasaf'), findsOneWidget);

    // Verify Goals formatted as GF:GA
    expect(find.text('12:3'), findsOneWidget);
    expect(find.text('10:5'), findsOneWidget);
    expect(find.text('8:6'), findsOneWidget);

    // Verify 1-line footer
    expect(find.text('G‘alaba 3 · Durang 1 · Mag‘lubiyat 0'), findsOneWidget);
  });

  testWidgets('StandingsPage info button opens rules bottom sheet', (tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap info icon in AppBar
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Verify BottomSheet content
    expect(find.text('Qoidalar va qisqartmalar'), findsOneWidget);
    expect(find.text('Ochko hisoblash tizimi:'), findsOneWidget);
    expect(find.text('Tenglik bo‘lganda joylashuv tartibi:'), findsOneWidget);
    expect(find.text('Jadval ustunlari qisqartmalari:'), findsOneWidget);
  });
}
