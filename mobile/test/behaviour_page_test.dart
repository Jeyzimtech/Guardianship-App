import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/features/parent/behaviour_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('Behaviour page fits $width with enlarged text', (
      tester,
    ) async {
      await mount(
        tester,
        const BehaviourView(child: {'name': 'Alice Chewe'}),
        width: width,
        scale: 1.3,
      );
      expect(find.textContaining('Alice Chewe'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Conduct filters combine with search and reset', (tester) async {
    await mount(tester, const BehaviourView());
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Conduct notes'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Conduct notes'));
    expect(find.text('1 record'), findsOneWidget);
    expect(find.text('Late Homework Submission'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'leadership');
    await tester.pumpAndSettle();
    expect(find.text('No matching activity'), findsOneWidget);
    await tapVisible(tester, find.text('Reset filters'));
    expect(find.text('3 records'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Merits'));
    expect(find.text('2 records'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'arithmetic');
    await tester.pumpAndSettle();
    expect(find.text('1 record'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Clear search'));
    expect(find.text('2 records'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
