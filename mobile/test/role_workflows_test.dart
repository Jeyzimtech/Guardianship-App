import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/features/parent/fee_payments_view.dart';
import 'package:guardianship/features/teacher/teacher_publish_page.dart';
import 'package:guardianship/features/parent/uniform_marketplace_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:guardianship/core/app_colors.dart';

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
  final previewKey = GlobalKey();
  Future<void> preview(WidgetTester tester, String name) async {
    final boundary =
        previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('output/role-workflows').create(recursive: true);
      await File(
        'output/role-workflows/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(WidgetTester tester, Widget page, ApiClient api) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => StudentProvider(api)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'Cabin',
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          home: RepaintBoundary(key: previewKey, child: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Uniform order checks PesePay and displays verified test payment',
    (tester) async {
      final api = ApiClient();
      bool paid = false;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.path.endsWith('/payment-status')) paid = true;
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'uniforms': [],
                  'payment_status': paid ? 'paid' : 'pending',
                  'gateway_status': 'SUCCESS',
                  'orders': [
                    {
                      'id': 1,
                      'items': [],
                      'currency': 'USD',
                      'total_amount': 1,
                      'payment_status': paid ? 'paid' : 'pending',
                      'latest_payment': {'sandbox': true},
                      'payment_method': paid ? 'PesePay' : null,
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      await mount(
        tester,
        const UniformMarketplaceView(child: {'id': 1, 'school_id': 1}),
        api,
      );
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Check payment status'));
      await tester.tap(find.text('Check payment status'));
      await tester.pumpAndSettle();
      expect(paid, isTrue);
      expect(find.text('Test payment verified'), findsOneWidget);
      expect(find.text('Pay with PesePay'), findsNothing);
      expect(find.textContaining('Roadrunner'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Teacher publishes a note for an assigned student and subject', (
    tester,
  ) async {
    final api = ApiClient();
    Map<String, String>? posted;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (o.method == 'POST') {
            posted = Map.fromEntries((o.data as FormData).fields);
          }
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {
                'students': [
                  {
                    'id': 1,
                    'name': 'Assigned learner',
                    'grade': '1',
                    'class_name': 'Blue',
                  },
                ],
                'classes': [
                  {
                    'id': 1,
                    'grade': '1',
                    'class_name': 'Blue',
                    'pivot': {'subject_name': 'Mathematics'},
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    await mount(tester, const TeacherPublishPage(), api);
    if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
      await preview(tester, 'teacher-journal');
    }
    await tester.enterText(
      find.byType(TextFormField),
      'Good progress with counting.',
    );
    await tester.ensureVisible(find.text('Publish entry'));
    await tester.tap(find.text('Publish entry'));
    await tester.pumpAndSettle();
    expect(posted?['student_id'], '1');
    expect(posted?['subject_name'], 'Mathematics');
    expect(posted?['caption'], 'Good progress with counting.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report upload requires a file and empty classes stay empty', (
    tester,
  ) async {
    final api = ApiClient();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(
          Response(
            requestOptions: o,
            statusCode: 200,
            data: {'students': [], 'classes': []},
          ),
        ),
      ),
    );
    await mount(tester, const TeacherPublishPage(report: true), api);
    expect(find.textContaining('No assigned students yet'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fee references remain pending and do not lower the displayed balance',
    (tester) async {
      final api = ApiClient();
      Map<String, dynamic>? posted;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.method == 'POST') posted = Map<String, dynamic>.from(o.data);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: o.method == 'POST' ? 202 : 200,
                data: {
                  'fee_account': {
                    'balance_usd': '100.00',
                    'balance_zig': '0.00',
                  },
                  'transactions': posted == null
                      ? []
                      : [
                          {
                            'amount': 10,
                            'currency': 'USD',
                            'status': 'pending',
                            'reference': 'receipt-123',
                          },
                        ],
                },
              ),
            );
          },
        ),
      );
      await mount(tester, const FeePaymentsView(child: {'id': 1}), api);
      if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
        await preview(tester, 'parent-fees');
      }
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.enterText(find.byType(TextFormField).last, 'receipt-123');
      await tester.ensureVisible(find.text('Submit reference'));
      await tester.tap(find.text('Submit reference'));
      await tester.pumpAndSettle();
      expect(posted?['student_id'], 1);
      expect(posted?['reference'], 'receipt-123');
      expect(find.textContaining('100.00'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('10 · pending'));
      expect(find.textContaining('10 · pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
