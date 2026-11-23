import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/legal.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/features/auth/login_screen.dart';
import 'package:guardianship/features/legal/consent_screen.dart';
import 'package:guardianship/features/profile/profile_view.dart';
import 'package:guardianship/features/support/report_issue_page.dart';
import 'package:guardianship/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_pages_test.dart' show ProfileAuth;
import 'supporting_pages_test.dart' show mount, tapVisible;

/// Scrolls lazily built lists until [finder] exists, then taps it.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  }
  await tapVisible(tester, finder);
}

Widget app(ApiClient api) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(api)),
    ChangeNotifierProvider(create: (_) => StudentProvider(api)),
  ],
  child: const EduConectApp(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Edu Connect', packageName: 'educonnect.com', version: '1.0.8', buildNumber: '9', buildSignature: '',
    );
  });

  testWidgets('First launch asks for consent, explains when not understood, then remembers it', (tester) async {
    await tester.pumpWidget(app(ApiClient()));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tapOn(tester, find.text('I don\'t understand'));
    expect(find.text('Email us a question'), findsOneWidget);
    await tapOn(tester, find.text('Go back'));
    expect(find.byType(ConsentScreen), findsOneWidget);

    await tapOn(tester, find.text('Privacy policy'));
    expect(find.text('What we collect'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapOn(tester, find.text('I understand and agree'));
    expect(find.byType(LoginScreen), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(Legal.acceptedKey), Legal.version);
  });

  testWidgets('Accepted policy skips consent, and an older acceptance asks again', (tester) async {
    SharedPreferences.setMockInitialValues({Legal.acceptedKey: Legal.version});
    await tester.pumpWidget(app(ApiClient()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    SharedPreferences.setMockInitialValues({Legal.acceptedKey: '2020-01-01'});
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(ApiClient()));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentScreen), findsOneWidget);
  });

  test('Logging out keeps the policy acceptance', () async {
    SharedPreferences.setMockInitialValues({Legal.acceptedKey: Legal.version, 'auth_token': 't', 'user_role': 'guardian'});
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(Response(requestOptions: o, statusCode: 200, data: {'status': 'success'})),
    ));
    await AuthProvider(api).logout();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString(Legal.acceptedKey), Legal.version);
  });

  test('Account deletion keeps the session when the server refuses', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 't', 'user_role': 'guardian', 'user_name': 'P'});
    final api = ApiClient();
    var calls = 0;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.path == '/auth/delete-account') {
        calls++;
        return calls == 1
            ? h.reject(DioException(requestOptions: o, response: Response(requestOptions: o, statusCode: 500)))
            : h.resolve(Response(requestOptions: o, statusCode: 200, data: {'status': 'success'}));
      }
      h.resolve(Response(requestOptions: o, statusCode: 200, data: {'status': 'success', 'user': {'name': 'P', 'role': 'guardian'}}));
    }));
    final auth = AuthProvider(api);
    await Future<void>.delayed(Duration.zero);
    expect(await auth.deleteAccount(), isFalse);
    expect(auth.isAuthenticated, isTrue);
    expect(await auth.deleteAccount(), isTrue);
    expect(auth.isAuthenticated, isFalse);
  });

  for (final teacher in [true, false]) {
    testWidgets('${teacher ? 'Teacher' : 'Parent'} profile links to help, legal and app info', (tester) async {
      final auth = ProfileAuth(teacher);
      addTearDown(auth.dispose);
      await mount(tester, ChangeNotifierProvider<AuthProvider>.value(value: auth, child: const ProfileView()), width: 360);
      for (final label in ['Privacy policy', 'Terms of use', 'Help center', 'Report a technical issue', 'Send feedback', 'App info', 'Delete account']) {
        await tapOn(tester, find.text(label));
        expect(tester.takeException(), isNull);
        if (label == 'Delete account') {
          expect(find.text('Delete account?'), findsOneWidget);
          await tapOn(tester, find.text('Cancel'));
          continue;
        }
        if (label == 'Help center') expect(find.text(Legal.supportEmail), findsWidgets);
        if (label == 'App info') expect(find.text('1.0.8 (9)'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('Issue report validates and posts the details with the app version', (tester) async {
    Map<String, dynamic>? sent;
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.path == '/support/reports') sent = Map<String, dynamic>.from(o.data);
      h.resolve(Response(requestOptions: o, statusCode: 201, data: {'status': 'success'}));
    }));
    final auth = AuthProvider(api);
    addTearDown(auth.dispose);
    // The provider sits above the navigator so the pushed page posts through [api].
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage())),
        child: const Text('open'),
      )))),
    ));
    await tapVisible(tester, find.text('open'));
    await tapOn(tester, find.text('Send report'));
    expect(find.text('Please describe the problem in a little more detail'), findsOneWidget);
    expect(sent, isNull);

    await tester.enterText(find.byType(TextFormField), 'The homework page stays blank after opening.');
    await tapOn(tester, find.text('Send report'));
    expect(sent?['category'], 'bug');
    expect(sent?['message'], 'The homework page stays blank after opening.');
    expect(sent?['app_version'], '1.0.8 (9)');
    expect(find.text('Thank you. Your report has been sent to our support team.'), findsOneWidget);
  });
}
