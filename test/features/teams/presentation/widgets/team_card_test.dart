import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/features/teams/domain/entities/team_entity.dart';
import 'package:football_tournament_manager/features/teams/presentation/widgets/team_card.dart';

void main() {
  final testTeam = TeamEntity(
    id: '678b561b-abcd-1234-5678-abcdef012345',
    name: 'Nasaf',
    colorValue: 0xFF003399,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('TeamCard displays matches and points statistics instead of ID', (tester) async {
    await tester.pumpWidget(wrapWidget(
      TeamCard(
        team: testTeam,
        played: 4,
        points: 7,
        hasMatches: true,
        onEdit: () {},
        onDeleteOrArchive: () {},
      ),
    ));

    // Must NOT display "ID: 678b561b"
    expect(find.textContaining('ID:'), findsNothing);
    expect(find.textContaining('678b561b'), findsNothing);

    // Must display statistics
    expect(find.text('O‘yinlar: 4 · Ochko: 7'), findsOneWidget);
  });

  testWidgets('TeamCard shows archive icon when team has matches', (tester) async {
    await tester.pumpWidget(wrapWidget(
      TeamCard(
        team: testTeam,
        played: 3,
        points: 6,
        hasMatches: true,
        onEdit: () {},
        onDeleteOrArchive: () {},
      ),
    ));

    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('TeamCard shows delete icon when team has no matches', (tester) async {
    await tester.pumpWidget(wrapWidget(
      TeamCard(
        team: testTeam,
        played: 0,
        points: 0,
        hasMatches: false,
        onEdit: () {},
        onDeleteOrArchive: () {},
      ),
    ));

    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.archive_outlined), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });
}
