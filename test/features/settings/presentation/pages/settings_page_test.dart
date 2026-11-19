import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/theme/app_theme.dart';
import 'package:football_tournament_manager/features/schedule/domain/repositories/match_repository.dart';
import 'package:football_tournament_manager/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:football_tournament_manager/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:football_tournament_manager/features/settings/presentation/pages/settings_page.dart';
import 'package:football_tournament_manager/features/teams/domain/repositories/team_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockMatchRepository extends Mock implements MatchRepository {}
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockSharedPreferences mockPrefs;
  late MockMatchRepository mockMatchRepo;
  late MockTeamRepository mockTeamRepo;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockMatchRepo = MockMatchRepository();
    mockTeamRepo = MockTeamRepository();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
  });

  Widget createWidgetUnderTest({int mockDelay = 400}) {
    when(() => mockPrefs.getInt('app_mock_delay')).thenReturn(mockDelay);
    final cubit = SettingsCubit(prefs: mockPrefs);
    final scheduleBloc = ScheduleBloc(
      matchRepository: mockMatchRepo,
      teamRepository: mockTeamRepo,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: cubit),
        BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsPage(),
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

  testWidgets('SettingsPage renders with NO crash when mockDelay is 400 (was crashing with DropdownButton)',
      (WidgetTester tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest(mockDelay: 400));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Mavzu (Theme)'), findsOneWidget);
    expect(find.text('400 ms'), findsOneWidget);
  });

  testWidgets('SettingsPage renders safely with extreme mockDelay values without crashing',
      (WidgetTester tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest(mockDelay: 9999));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('SettingsPage allows changing theme mode via SegmentedButton',
      (WidgetTester tester) async {
    setupScreen(tester);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final lightThemeSegment = find.text('Kun');
    expect(lightThemeSegment, findsOneWidget);

    await tester.tap(lightThemeSegment);
    await tester.pumpAndSettle();

    verify(() => mockPrefs.setString('app_theme_mode', 'light')).called(1);
  });
}
