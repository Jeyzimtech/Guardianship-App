import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/features/school_management/school_management_screen.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('Teacher school directory fits $width and opens details', (
      tester,
    ) async {
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {
                'status': 'success',
                'schools': [
                  {
                    'id': 1,
                    'name': 'Hillside Primary School',
                    'type': 'primary',
                    'students_count': 230,
                    'teachers_count': 12,
                  },
                ],
                'academic_years': [
                  {
                    'id': 1,
                    'name': 'Term 3 2026',
                    'code': 'T3',
                    'is_current': true,
                  },
                ],
                'classes': [
                  {
                    'id': 1,
                    'grade': 'Grade 4',
                    'class_name': 'Gold',
                    'school': {'name': 'Hillside Primary School'},
                    'capacity': 35,
                  },
                ],
              },
            ),
          ),
        ),
      );
      await mount(
        tester,
        Provider<ApiClient>.value(
          value: api,
          child: const SchoolManagementScreen(),
        ),
        width: width,
        scale: 1.3,
      );
      expect(find.text('Add campus'), findsNothing);
      await tapVisible(tester, find.text('View details'));
      expect(find.text('Hillside Primary School'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Close'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Terms'));
      expect(find.text('Active term'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Classes'));
      expect(find.text('Grade 4 Gold'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no results');
      await tester.pumpAndSettle();
      expect(find.text('No matching records'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Clear search'));
      expect(find.text('Grade 4 Gold'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
