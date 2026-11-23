import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/app_colors.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/core/subscription_provider.dart';
import 'package:guardianship/features/parent/subscription_boundary.dart';
import 'package:guardianship/features/parent/subscription_page.dart';
import 'package:guardianship/features/parent/child_information_page.dart';
import 'package:guardianship/features/parent/activity_participation_page.dart';
import 'package:guardianship/features/parent/payment_proof_page.dart';
import 'package:guardianship/features/parent/parent_dashboard_view.dart';
import 'package:guardianship/features/teacher/teacher_publish_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting_pages_test.dart' show tapVisible;

class FeatureAuth extends AuthProvider {
  final String role;
  FeatureAuth(super.apiClient, {this.role = 'guardian'});
  @override
  bool get isAuthenticated => true;
  @override
  bool get isGuardian => role == 'guardian';
  @override
  bool get isTeacher => role == 'teacher';
  @override
  Map<String, dynamic> get user => {'id': 42, 'role': role, 'name': 'Parent'};
  @override
  String get token => 'fixture-token';
}

class FeatureStudents extends StudentProvider {
  FeatureStudents(super.apiClient);
  static final child = <String, dynamic>{
    'id': 1,
    'name': 'Alice',
    'grade': '1',
    'class_name': 'Blue',
    'school': {'name': 'School One'},
    'school_id': 1,
    'dob': '2020-01-02',
  };
  @override
  Map<String, dynamic> get selectedStudent => child;
  @override
  List<dynamic> get students => [child];
  @override
  Map<String, dynamic> get dashboardData => {
    'attendance_snapshot': {'percentage': 100},
  };
}

Future<void> mountFeature(
  WidgetTester tester,
  Widget page, {
  String role = 'guardian',
  SubscriptionProvider? access,
  bool boundary = false,
  double width = 430,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = ApiClient();
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(
        Response(
          requestOptions: o,
          statusCode: 200,
          data: {
            'status': 'success',
            'fee_account': {'balance_usd': 100, 'balance_zig': 0},
            'transactions': [],
            'activities': [
              {
                'title': 'Football practice',
                'activity_date': '2026-11-20',
                'status': 'present',
                'description': 'After school sports',
              },
            ],
            'students': [FeatureStudents.child],
            'classes': [],
            'entries': [],
            'data': {'entries': []},
          },
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => FeatureAuth(api, role: role),
        ),
        ChangeNotifierProvider<StudentProvider>(
          create: (_) => FeatureStudents(api),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => access ?? SubscriptionProvider(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'Cabin',
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        builder: boundary
            ? (_, child) => SubscriptionBoundary(child: child!)
            : null,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() => featureTests();

void featureTests({bool systemBack = true}) {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'subscription_notice_42': true,
    }),
  );
  testWidgets('Suspended parent cannot see open content or bypass using Back', (
    tester,
  ) async {
    final access = SubscriptionProvider()
      ..loading = false
      ..allowed = false;
    await mountFeature(
      tester,
      const Scaffold(body: Text('Private school record')),
      access: access,
      boundary: true,
    );
    expect(find.text('Private school record'), findsNothing);
    expect(find.text('Account access'), findsOneWidget);
    if (systemBack) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.text('Private school record'), findsNothing);
    expect(find.text('Account access'), findsOneWidget);
    access.allowed = true;
    access.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Private school record'), findsOneWidget);
  });
  testWidgets('Teachers never see the subscription gate', (tester) async {
    await mountFeature(
      tester,
      const Scaffold(body: Text('Teacher work')),
      role: 'teacher',
      boundary: true,
    );
    expect(find.text('Teacher work'), findsOneWidget);
    expect(find.text('Account access'), findsNothing);
  });
  testWidgets(
    'Account access has support information without purchase prompts',
    (tester) async {
      final access = SubscriptionProvider()..loading = false;
      await mountFeature(
        tester,
        const SubscriptionPage(restricted: true),
        access: access,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Contact for activation'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('079 054 3013'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 800.0]) {
    testWidgets('Subscription benefits and contact fit width $width', (
      tester,
    ) async {
      final access = SubscriptionProvider()..loading = false;
      await mountFeature(
        tester,
        const SubscriptionPage(restricted: true),
        access: access,
        width: width,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('079 054 3013'), findsOneWidget);
    });
  }
  testWidgets('Dashboard omits the removed essentials shortcuts', (
    tester,
  ) async {
    await mountFeature(tester, const ParentDashboardView());
    expect(find.text('Your school essentials'), findsNothing);
    expect(find.text('Uniform store'), findsNothing);
    for (final title in [
      'Child information',
      'Proof of payment',
      'School documents',
      'Profile',
    ])
      expect(find.text(title), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Child information shows school-owned details', (tester) async {
    await mountFeature(tester, const ChildInformationPage());
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('School One'), findsOneWidget);
    expect(find.text('2020-01-02'), findsOneWidget);
  });
  testWidgets('Activities show school-recorded participation', (tester) async {
    await mountFeature(tester, const ActivityParticipationPage());
    expect(find.text('Football practice'), findsOneWidget);
    expect(find.text('Took part'), findsOneWidget);
    expect(find.text('New activity'), findsNothing);
  });
  testWidgets('Payment form validates required amount and reference', (
    tester,
  ) async {
    await mountFeature(tester, const PaymentProofPage());
    await tapVisible(tester, find.text('Submit for verification'));
    expect(find.text('Enter an amount of at least 1'), findsOneWidget);
    expect(find.text('Enter the payment reference'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Parent submits payment reference for school verification', (
    tester,
  ) async {
    await mountFeature(tester, const PaymentProofPage());
    await tester.enterText(find.byType(TextFormField).at(0), '10');
    await tester.enterText(find.byType(TextFormField).at(1), 'REF-123');
    await tapVisible(tester, find.text('Submit for verification'));
    expect(
      find.text('Proof submitted. Your school will verify the payment.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Journal authoring no longer offers drawings', (tester) async {
    await mountFeature(tester, const TeacherPublishPage(), role: 'teacher');
    expect(find.text('Drawing'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
