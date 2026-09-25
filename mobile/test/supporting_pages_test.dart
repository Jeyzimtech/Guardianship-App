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
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(ApiClient()),
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
    expect(find.text('13 merits'), findsOneWidget);
    await tapVisible(tester, find.text('Roll call'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Absent'));
    await reveal(tester, find.text('2 absent'));
    expect(find.text('2 absent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Gradebook saves edited marks', (tester) async {
    await mount(tester, const TeacherDashboardView(), width: 320);
    await tapVisible(tester, find.text('Gradebook'));
    await tapVisible(tester, find.text('Edit marks'));
    await tester.enterText(find.byType(TextFormField).first, '93');
    await tapVisible(tester, find.text('Save Marks'));
    await reveal(tester, find.text('93%'));
    expect(find.text('93%'), findsOneWidget);
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
    await reveal(tester, find.text('Class reading day'));
    expect(find.text('Class reading day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Homework exposes overdue filter', (tester) async {
    await mount(tester, const AssignmentsView());
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Overdue'));
    expect(find.text('Photosynthesis Observation Journal'), findsOneWidget);
    expect(find.text('Fractions & Decimals Exercise Set 3'), findsNothing);
  });
  testWidgets('Inbox search displays empty state and opens a conversation', (
    tester,
  ) async {
    await mount(tester, const MessagingView());
    await tester.enterText(find.byType(TextField).first, 'no match');
    await tester.pumpAndSettle();
    expect(find.text('No conversations found'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Support');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Edu+Conect Support'));
    expect(find.text('Edu+Conect Support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
