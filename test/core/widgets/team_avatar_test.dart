import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/widgets/team_avatar.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('TeamAvatar differentiates collisions like Nasaf vs Navbahor with 3 letters', (tester) async {
    await tester.pumpWidget(wrapWidget(
      const Column(
        children: [
          TeamAvatar(name: 'Nasaf', colorValue: 0xFF003399),
          TeamAvatar(name: 'Navbahor', colorValue: 0xFFCC0000),
          TeamAvatar(name: 'Arsenal', colorValue: 0xFFEF0107),
          TeamAvatar(name: 'Real Madrid', colorValue: 0xFFFFFFFF),
        ],
      ),
    ));

    expect(find.text('NAS'), findsOneWidget);
    expect(find.text('NAV'), findsOneWidget);
    expect(find.text('ARS'), findsOneWidget);
    expect(find.text('RM'), findsOneWidget);
  });

  testWidgets('TeamAvatar has no heavy boxShadow glow', (tester) async {
    await tester.pumpWidget(wrapWidget(
      const TeamAvatar(name: 'Paxtakor', colorValue: 0xFFFFCC00),
    ));

    final containerFinder = find.byType(Container).first;
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNotNull);
  });

  testWidgets('TeamAvatar extracts clean Cyrillic initials from team names ending in ФК', (tester) async {
    await tester.pumpWidget(wrapWidget(
      const Column(
        children: [
          TeamAvatar(name: 'Шохгузар ФК', colorValue: 0xFF00897B),
          TeamAvatar(name: 'Булокбоши ФК', colorValue: 0xFF00C853),
          TeamAvatar(name: 'Фахрийлар ФК', colorValue: 0xFFFFB300),
          TeamAvatar(name: 'Кезар ФК', colorValue: 0xFF00ACC1),
        ],
      ),
    ));

    expect(find.text('ШОХ'), findsOneWidget);
    expect(find.text('БУЛ'), findsOneWidget);
    expect(find.text('ФАХ'), findsOneWidget);
    expect(find.text('КЕЗ'), findsOneWidget);
  });
}
