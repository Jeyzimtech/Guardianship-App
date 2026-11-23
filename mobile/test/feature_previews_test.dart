import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/chat/chat_view.dart';
import 'package:guardianship/features/teacher/teacher_dashboard_view.dart';
import 'package:guardianship/features/teacher/teacher_sos_card.dart';
import 'package:guardianship/main.dart';
import 'package:guardianship/features/dashboard/announcements_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreviewAuth extends AuthProvider {
  final String role;
  PreviewAuth(super.apiClient, this.role);
  @override
  Map<String, dynamic>? get user => {'id': 17, 'role': role, 'name': 'Teacher'};
  @override
  bool get isTeacher => role == 'teacher';
  @override
  bool get isGuardian => role == 'guardian';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fallback = ByteData.sublistView(
      await File('test/fixtures/Roboto-Regular.ttf').readAsBytes(),
    );
    await (FontLoader('Roboto')..addFont(Future.value(fallback))).load();
    await (FontLoader(
      'Cabin',
    )..addFont(rootBundle.load('assets/fonts/Cabin.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final key = GlobalKey();
  ThemeData androidTheme(BuildContext context) {
    final theme = (const EduConectApp().build(context) as MaterialApp).theme!;
    // Android uses Roboto for explicit styles without a font family.
    // Widget tests otherwise render these styles with the Ahem test font.
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Roboto',
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: theme.outlinedButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            theme.outlinedButtonTheme.style?.textStyle
                ?.resolve({})
                ?.copyWith(fontFamily: 'Roboto'),
          ),
        ),
      ),
    );
  }

  Future<void> mount(
    WidgetTester tester,
    Widget page,
    ApiClient api, {
    String role = 'teacher',
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => PreviewAuth(api, role),
        child: RepaintBoundary(
          key: key,
          child: Builder(
            builder: (context) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: androidTheme(context),
              home: page,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('output/feature-previews').create(recursive: true);
      await File(
        'output/feature-previews/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'Saved previous register shows CSV download in teacher roll call',
    (tester) async {
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'categories': [],
                  'activities': [],
                  'roster': [
                    {
                      'student_id': 1,
                      'name': 'Tariro Moyo',
                      'grade': '3',
                      'class_name': 'Blue',
                      'status': 'present',
                      'marked': true,
                      'guardians': [],
                    },
                    {
                      'student_id': 2,
                      'name': 'Tendai Ncube',
                      'grade': '3',
                      'class_name': 'Blue',
                      'status': 'late',
                      'marked': true,
                      'guardians': [],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      await mount(tester, const TeacherDashboardView(initialTab: 1), api);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Download saved CSV'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Register saved for'), findsOneWidget);
      await capture(tester, 'teacher-register-csv');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Message selection deletes only selected IDs and shows confirmation',
    (tester) async {
      final api = ApiClient();
      final messages = [
        {
          'id': 1,
          'body': 'Tariro has completed her reading activity today.',
          'from_me': true,
          'created_at': '2026-10-23 08:30:00',
        },
        {
          'id': 2,
          'body': 'Thank you for the update, teacher.',
          'from_me': false,
          'created_at': '2026-10-23 08:32:00',
        },
        {
          'id': 3,
          'body': 'Please remember to bring the reading book tomorrow.',
          'from_me': true,
          'created_at': '2026-10-23 08:34:00',
        },
      ];
      Map? deleted;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.method == 'DELETE') {
              deleted = o.data as Map;
              messages.removeWhere(
                (m) => (deleted!['ids'] as List).contains(m['id']),
              );
            }
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {'messages': List.of(messages)},
              ),
            );
          },
        ),
      );
      await mount(
        tester,
        const ConversationView(
          contact: {
            'id': 5,
            'name': 'Mrs Moyo',
            'role': 'guardian',
            'students': ['Tariro Moyo'],
          },
        ),
        api,
      );
      await tester.longPress(
        find.text('Tariro has completed her reading activity today.'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thank you for the update, teacher.'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await capture(tester, 'message-selection');
      await tester.tap(find.byTooltip('Delete selected messages'));
      await tester.pumpAndSettle();
      await capture(tester, 'message-delete-confirmation');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted!['ids'], [1, 2]);
      expect(
        find.text('Tariro has completed her reading activity today.'),
        findsNothing,
      );
      expect(
        find.text('Please remember to bring the reading book tomorrow.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'SOS defaults to one parent and all parents requires confirmation',
    (tester) async {
      final api = ApiClient();
      final sent = <Map>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.method == 'POST') sent.add(Map.from(o.data as Map));
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: o.method == 'POST' ? 201 : 200,
                data: {
                  'contacts': [
                    {
                      'id': 1,
                      'name': 'Mrs Moyo',
                      'students': ['Tariro Moyo'],
                    },
                    {
                      'id': 2,
                      'name': 'Mr Ncube',
                      'students': ['Tendai Ncube'],
                    },
                  ],
                  'message': 'SOS saved. SMS accepted for selected recipients.',
                  'recipients': 1,
                },
              ),
            );
          },
        ),
      );
      await mount(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Teacher home')),
          body: const Padding(
            padding: EdgeInsets.all(20),
            child: TeacherSosCard(),
          ),
        ),
        api,
      );
      await tester.tap(find.text('Choose SOS recipients'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {false},
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send SOS'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Mr Ncube'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mrs Moyo'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Mr Ncube'),
            )
            .value,
        false,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Emergency message'),
        'Tariro is unwell. Please contact the school office.',
      );
      await tester.pumpAndSettle();
      await capture(tester, 'sos-one-parent');
      await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(sent.single['guardian_ids'], [1]);
      expect(sent.single.containsKey('audience'), false);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose SOS recipients'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All parents'));
      await tester.pumpAndSettle();
      await capture(tester, 'sos-all-parents');
      await tester.tap(find.text('Review all parents'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(sent.length, 1);
      await capture(tester, 'sos-all-confirmation');
      await tester.tap(find.text('Send to all parents'));
      await tester.pumpAndSettle();
      expect(sent.length, 2);
      expect(sent.last['audience'], 'all');
      expect(sent.last.containsKey('guardian_ids'), false);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final role in ['teacher', 'guardian']) {
    testWidgets(
      '$role deletes selected notifications and then all remaining updates',
      (tester) async {
        final api = ApiClient();
        final notices = [
          {
            'id': 11,
            'title': 'Sports day',
            'content': 'Sports day is on Friday.',
            'audience_role': 'all',
            'category': 'School Events',
            'created_at': '2026-10-23T08:00:00Z',
          },
          {
            'id': 12,
            'title': 'School reminder',
            'content': 'Please return the permission slip.',
            'audience_role': 'all',
            'category': 'General',
            'created_at': '2026-10-22T08:00:00Z',
          },
        ];
        final alerts = [
          {
            'id': 5,
            'message': 'Please contact the school office.',
            'teacher_name': 'Class teacher',
            'created_at': '2026-10-23 09:00:00',
          },
        ];
        final deleted = <Map>[];
        api.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              if (o.method == 'DELETE') {
                final items = (o.data['items'] as List).cast<Map>();
                deleted.addAll(items);
                for (final item in items) {
                  if (item['category'] == 'sos') {
                    alerts.removeWhere((a) => a['id'] == item['id']);
                  } else {
                    notices.removeWhere((a) => a['id'] == item['id']);
                  }
                }
              }
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'announcements': List.of(notices),
                    'alerts': List.of(alerts),
                  },
                ),
              );
            },
          ),
        );
        await mount(
          tester,
          const AnnouncementsView(notifications: true),
          api,
          role: role,
        );
        await tester.tap(find.text('Select notifications'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Select').first, 200, scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Select').first);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Delete selected'), -200, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.text('Delete selected'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete selected'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(deleted.length, 1);
        expect(
          deleted.single['category'],
          role == 'guardian' ? 'sos' : 'notices',
        );
        await tester.tap(find.text('Select notifications'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select all shown'));
        await tester.pumpAndSettle();
        await capture(tester, '$role-notification-selection');
        await tester.ensureVisible(find.text('Delete selected'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete selected'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(deleted.length, role == 'guardian' ? 3 : 2);
        expect(find.text('Select notifications'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
