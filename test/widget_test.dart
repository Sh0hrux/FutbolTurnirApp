import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_tournament_manager/core/widgets/team_avatar.dart';

void main() {
  testWidgets('TeamAvatar displays correct initials and color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => const TeamAvatar(
              name: 'Real Madrid',
              colorValue: 0xFF1E88E5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('RM'), findsOneWidget);
  });
}
