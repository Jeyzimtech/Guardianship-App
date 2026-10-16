import 'package:dio/dio.dart';
import 'package:guardianship/core/student_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/app_colors.dart';
import 'package:guardianship/features/teacher/teacher_dashboard_view.dart';
import 'package:guardianship/features/parent/assignments_view.dart';
import 'package:guardianship/features/parent/messaging_view.dart';
import 'package:guardianship/features/parent/learning_journal_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FixtureStudents extends StudentProvider {
  FixtureStudents(super.apiClient);
  @override
  Map<String, dynamic> get selectedStudent => {'id': 1, 'school_id': 1, 'name': 'Alice Chewe'};
}

ApiClient fixtureApi() {
  final api = ApiClient();
  bool ordered = false;
  api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    if (o.path == '/uniform-orders' && o.method == 'POST') ordered = true;
    final data = <String, dynamic>{'status': 'success', 'categories': [], 'activities': [], 'announcements': [], 'reports': [], 'entries': [], 'orders': ordered ? [{'id': 1, 'created_at': '2026-10-16', 'items': [], 'total_amount': 45, 'currency': 'USD', 'payment_status': 'pending'}] : [],
      'roster': [
        {'student_id': 1, 'name': 'Alice Chewe', 'class_name': 'Gold', 'status': 'present'},
        {'student_id': 2, 'name': 'Bob Chewe', 'class_name': 'Gold', 'status': 'absent'},
      ],
      'attendance': List.generate(7, (i) => {'date': '2026-10-${10+i}', 'status': i == 0 ? 'absent' : 'present', 'subject_name': 'Math'}),
      'uniforms': [{'id': 1, 'name': 'Official Embroidered School Blazer', 'category': 'Blazers', 'price': 45.0, 'price_usd': 45.0, 'price_zig': 1200.0, 'sizes': ['Size 30','Size 32'], 'in_stock': true, 'description': 'School blazer'}],
      'data': {'all': [{'title': 'Photosynthesis Observation Journal', 'subject_name': 'Science', 'description': 'Observe plants', 'due_date': '2020-01-01'}]}};
    h.resolve(Response(requestOptions: o, statusCode: 200, data: data));
  }));
  return api;
}

Future<void> mount(
  WidgetTester tester,
  Widget page, {
  double width = 430,
  double scale = 1,
  GlobalKey? boundary,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = fixtureApi();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider<StudentProvider>(create: (_) => FixtureStudents(api)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'Cabin',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(key: boundary, child: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder.first,
        250,
        scrollable: find.byType(Scrollable).first,
      );
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Cabin',
    )..addFont(rootBundle.load('assets/fonts/Cabin.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final pages = <String, Widget>{
    'classroom': const TeacherDashboardView(),
    'homework': const AssignmentsView(),
    'messages': const MessagingView(),
    'journal': const LearningJournalView(),
  };
  for (final page in pages.entries) {
    for (final width in [320.0, 430.0]) {
      testWidgets('${page.key} fits $width with enlarged text', (tester) async {
        await mount(tester, page.value, width: width, scale: 1.3);
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -450));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
    if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
      testWidgets('Preview ${page.key}', (tester) async {
        final boundary = GlobalKey();
        await mount(tester, page.value, boundary: boundary);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final capture = await render.toImage(pixelRatio: 2);
          final bytes = await capture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory('output/supporting-pages').create(recursive: true);
          await File(
            'output/supporting-pages/${page.key}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          capture.dispose();
        });
      });
    }
  }
  testWidgets('Roster search, merits and roll-call changes stay connected', (
    tester,
  ) async {
    await mount(tester, const TeacherDashboardView());
    await tester.enterText(find.byType(TextField).first, 'Alice');
    await tester.pumpAndSettle();
    expect(find.text('Alice Chewe'), findsOneWidget);
    expect(find.text('Bob Chewe'), findsNothing);
    await tapVisible(tester, find.text('Award merit'));
    await tapVisible(tester, find.text('Save'));
    expect(find.text('Behaviour saved for Alice Chewe.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tapVisible(tester, find.text('Roll call'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Absent'));
    await reveal(tester, find.text('2 absent'));
    expect(find.text('2 absent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Teacher guardian invitation validates details and submits the selected child', (tester) async {
    final api = fixtureApi();
    Map<String, dynamic>? invitation;
    api.dio.interceptors.insert(0, InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path == '/users') {
        invitation = Map<String, dynamic>.from(options.data);
        handler.resolve(Response(requestOptions: options, statusCode: 201, data: {'status':'success','email_sent':true,'message':'Setup link emailed.'}));
      } else { handler.next(options); }
    }));
    await mount(tester, ChangeNotifierProvider(create: (_) => AuthProvider(api), child: const TeacherDashboardView()));
    await tapVisible(tester, find.text('Invite guardian').first);
    await tapVisible(tester, find.text('Send invitation'));
    expect(find.text('Enter a name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Parent Example');
    await tester.enterText(find.byType(TextFormField).at(1), 'parent@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '+263771234567');
    await tapVisible(tester, find.text('Send invitation'));
    expect(invitation?['role'], 'guardian');
    expect(invitation?['student_ids'], [1]);
    expect(find.text('Setup link emailed.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Activities tab loads the empty roster state', (tester) async {
    await mount(tester, const TeacherDashboardView(), width: 320);
    await tapVisible(tester, find.text('Activities').first);
    expect(find.text('New activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Notice form validates and adds a notice', (tester) async {
    await mount(tester, const TeacherDashboardView(), width: 320);
    await tapVisible(tester, find.text('Notices'));
    await tapVisible(tester, find.text('Post notice'));
    expect(
      find.text('Please enter notice title and message details.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Class reading day');
    await tester.enterText(
      find.byType(TextField).last,
      'Please bring a favourite book.',
    );
    await tapVisible(tester, find.text('Post notice'));
    expect(find.text('Notice sent to parents in your class.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Homework exposes overdue filter', (tester) async {
    await mount(tester, const AssignmentsView());
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Overdue'));
    expect(find.text('Photosynthesis Observation Journal'), findsOneWidget);
    expect(find.text('Fractions & Decimals Exercise Set 3'), findsNothing);
  });
  testWidgets('Messages show persisted school notices and an empty search state', (tester) async {
    await mount(tester, const MessagingView());
    await tester.enterText(find.byType(TextField).first, 'no match');
    await tester.pumpAndSettle();
    expect(find.text('No updates match this view. Try another filter or pull down to refresh.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
