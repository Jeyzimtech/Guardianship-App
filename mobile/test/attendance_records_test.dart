import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/features/dashboard/attendance_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('Attendance fits $width with large text', (tester) async {
      await mount(tester, const AttendanceView(), width: width, scale: 1.3);
      for (var i = 0; i < 8; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Status and search combine and reset', (tester) async {
    await mount(tester, const AttendanceView());
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Absent'));
    expect(find.text('1 record'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'traffic');
    await tester.pumpAndSettle();
    expect(find.text('No matching records'), findsOneWidget);
    await tapVisible(tester, find.text('Reset filters'));
    expect(find.text('7 records'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
