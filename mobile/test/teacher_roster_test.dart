import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/features/teacher_management/teacher_management_screen.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets(
      'Roster fits $width, searches classes and shows teacher details',
      (tester) async {
        final api = ApiClient();
        api.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'teachers': [
                    {
                      'id': 1,
                      'user': {
                        'name': 'Teacher Grace',
                        'email': 'grace@example.com',
                      },
                      'school': {'name': 'Hillside Primary School'},
                      'subject_specialties': ['Mathematics', 'English'],
                      'assigned_classes': [
                        {
                          'id': 1,
                          'grade': 'Grade 4',
                          'class_name': 'Gold',
                          'pivot': {'subject_name': 'Mathematics'},
                        },
                      ],
                    },
                  ],
                  'schools': [],
                  'classes': [],
                },
              ),
            ),
          ),
        );
        await mount(
          tester,
          Provider<ApiClient>.value(
            value: api,
            child: const TeacherManagementScreen(),
          ),
          width: width,
          scale: 1.3,
        );
        expect(find.text('Add teacher'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('View teacher details'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapVisible(tester, find.text('View teacher details'));
        expect(find.text('grace@example.com'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('Close'));
        await tester.scrollUntilVisible(
          find.byType(TextField),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(find.byType(TextField), 'gold');
        await tester.pumpAndSettle();
        expect(find.text('1 teacher profiles'), findsOneWidget);
        await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Unassigned'));
        expect(find.text('No matching teachers'), findsOneWidget);
        await tapVisible(tester, find.text('Reset filters'));
        expect(find.text('1 teacher profiles'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
