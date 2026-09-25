import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/dashboard/announcements_view.dart';
import 'package:guardianship/features/teacher/create_assignment_page.dart';
import 'package:guardianship/features/parent/assignments_view.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

class TeacherAuth extends AuthProvider {
  TeacherAuth(super.apiClient);
  @override
  bool get isTeacher => true;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('Notices fit $width and read state persists', (tester) async {
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              data: {
                'status': 'success',
                'announcements': [
                  {
                    'id': 1,
                    'title': 'Sports day',
                    'content': 'Bring your sports kit.',
                    'audience_role': 'all',
                    'created_at': '2026-09-25',
                    'category': 'General',
                  },
                ],
              },
            ),
          ),
        ),
      );
      final auth = AuthProvider(api);
      await mount(
        tester,
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const AnnouncementsView(notifications: true),
        ),
        width: width,
        scale: 1.3,
      );
      await tapVisible(tester, find.text('Read notice'));
      expect(find.text('Sports day'), findsWidgets);
      await tapVisible(tester, find.text('Close'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Unread'));
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'notice_reads_local',
        ),
        ['1'],
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Teacher can reach authoring and validation prevents blank submission',
    (tester) async {
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              data: {
                'status': 'success',
                'data': [],
                'classes': [
                  {'id': 1, 'grade': '4', 'class_name': 'Gold'},
                ],
              },
            ),
          ),
        ),
      );
      final auth = TeacherAuth(api);
      await mount(
        tester,
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const AssignmentsView(),
        ),
        width: 320,
        scale: 1.3,
      );
      await tapVisible(tester, find.text('Create assignment'));
      expect(find.byType(CreateAssignmentPage), findsOneWidget);
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Create assignment'),
      );
      expect(find.text('Choose a class'), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final fail in [false, true]) {
    testWidgets('Assignment submit handles success=$fail', (tester) async {
      final api = ApiClient();
      Map<String, dynamic>? sent;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            sent = Map<String, dynamic>.from(o.data);
            if (fail) {
              h.reject(DioException(requestOptions: o));
            } else {
              h.resolve(
                Response(requestOptions: o, data: {'status': 'success'}),
              );
            }
          },
        ),
      );
      await mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAssignmentPage(
                    api: api,
                    classes: const [
                      {'id': 1, 'grade': '4', 'class_name': 'Gold'},
                    ],
                  ),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      );
      await tapVisible(tester, find.text('Open form'));
      await tapVisible(tester, find.byType(DropdownButtonFormField<int>));
      await tapVisible(tester, find.text('4 Gold').last);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Fractions practice',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Mathematics');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Complete exercises 1-5.',
      );
      await tapVisible(tester, find.text('Choose due date'));
      await tapVisible(tester, find.text('OK'));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Create assignment'),
      );
      expect(sent?['school_class_id'], 1);
      expect(sent?['title'], 'Fractions practice');
      expect(sent?['due_date'], isNotNull);
      expect(
        find.byType(CreateAssignmentPage),
        fail ? findsOneWidget : findsNothing,
      );
      if (fail) {
        expect(
          find.textContaining('Assignment was not saved.'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Notification load failure has retry', (tester) async {
    final api = ApiClient();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.reject(DioException(requestOptions: o)),
      ),
    );
    await mount(
      tester,
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(api),
        child: const AnnouncementsView(),
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Unable to load'), findsOneWidget);
  });
}
