import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/parent/student_medical_page.dart';
import 'package:guardianship/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final boundary = GlobalKey();
  Map<String, dynamic> data = {};
  bool failSave = false;
  Map? saved;

  Future<void> mount(
    WidgetTester tester, {
    bool editable = true,
    double width = 430,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, editable ? 960 : 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (o.method == 'PUT') {
            saved = Map.from(o.data);
            if (failSave) {
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            data = Map<String, dynamic>.from(o.data);
          }
          h.resolve(
            Response(requestOptions: o, statusCode: 200, data: {'data': data}),
          );
        },
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(api),
        child: Builder(
          builder: (ctx) {
            final app = const EduConectApp().build(ctx) as MaterialApp;
            return MaterialApp(
              theme: app.theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: boundary,
                child: StudentMedicalPage(
                  studentId: 1,
                  studentName: 'Tariro Moyo',
                  editable: editable,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final picture = await render.toImage(pixelRatio: 2);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory('output/medical-preview').create(recursive: true);
      await File(
        'output/medical-preview/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  for (final width in [320.0, 430.0]) {
    testWidgets(
      'Parent medical form fits $width, saves only medical fields and retains failed edits',
      (tester) async {
        data = {};
        failSave = false;
        saved = null;
        await mount(tester, width: width, scale: 1.3);
        await tester.enterText(find.byType(TextField).first, 'Peanut allergy');
        await tester.scrollUntilVisible(
          find.text('Save medical details'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Save medical details'));
        await tester.pumpAndSettle();
        expect(saved?['allergies'], 'Peanut allergy');
        expect(saved?['conditions'], null);
        expect(find.text('Medical details saved.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        failSave = true;
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save medical details'));
        await tester.tap(find.text('Save medical details'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Your changes are still here.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final editable in [true, false]) {
    testWidgets(
      'Medical ${editable ? 'parent form' : 'teacher summary'} preview',
      (tester) async {
        data = {
          'allergies': 'Peanuts',
          'conditions': 'None reported',
          'medications': 'None reported',
          'care_instructions': 'Please contact me if there is any concern.',
          'updated_at': '2026-10-20T09:00:00Z',
        };
        failSave = false;
        await mount(tester, editable: editable);
        expect(tester.takeException(), isNull);
        if (!editable) {
          expect(find.byType(TextField), findsNothing);
          expect(find.text('Save medical details'), findsNothing);
        }
        await capture(
          tester,
          editable ? 'parent-medical-details' : 'teacher-medical-summary',
        );
      },
    );
  }
}
