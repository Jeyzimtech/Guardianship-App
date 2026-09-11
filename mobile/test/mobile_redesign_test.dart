import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/common/editorial_widgets.dart';
import 'package:guardianship/features/parent/parent_dashboard_view.dart';
import 'package:guardianship/features/teacher/teacher_home_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final name in ['Cabin']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final teacher in [false, true]) {
    for (final width in [320.0, 430.0]) {
      for (final scale in [1.0, 1.4]) {
        testWidgets(
          '${teacher ? 'Teacher' : 'Parent'} editorial layout $width at $scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (_) => AuthProvider(ApiClient()),
                child: MaterialApp(
                  theme: ThemeData(fontFamily: 'Cabin'),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: teacher
                        ? const TeacherHomeView()
                        : const ParentDashboardView(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              find.text(
                teacher ? 'Make room\nfor learning.' : 'A good day\nto learn.',
              ),
              findsOneWidget,
            );
            expect(find.text('Fee Payments'), findsNothing);
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 8; i++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -450),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }

  if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
    for (final teacher in [false, true]) {
      testWidgets(
        'Capture ${teacher ? 'teacher' : 'parent'} editorial preview',
        (tester) async {
          tester.view.physicalSize = const Size(430, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AuthProvider(ApiClient()),
              child: MaterialApp(
                theme: ThemeData(fontFamily: 'Cabin'),
                home: RepaintBoundary(
                  key: boundary,
                  child: Scaffold(
                    backgroundColor: Editorial.canvas,
                    appBar: AppBar(
                      backgroundColor: Editorial.canvas,
                      title: const Text('Edu+Conect'),
                      leading: const Icon(Icons.menu),
                    ),
                    body: teacher
                        ? const TeacherHomeView()
                        : const ParentDashboardView(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final capture = await render.toImage(pixelRatio: 2);
            final bytes = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('output/editorial').create(recursive: true);
            await File(
              'output/editorial/${teacher ? 'teacher' : 'parent'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            capture.dispose();
          });
        },
      );
    }
  }
}
