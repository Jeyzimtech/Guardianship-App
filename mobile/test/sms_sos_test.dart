import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/auth/phone_login_screen.dart';
import 'package:guardianship/features/teacher/teacher_sos_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('SMS request switches to code entry without email or password', (tester) async {
    final api = ApiClient();
    String? phone;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      phone = o.data['phone_number'];
      h.resolve(Response(requestOptions: o, statusCode: 200, data: {'challenge_id': 'challenge'}));
    }));
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AuthProvider(api), child: const MaterialApp(home: PhoneLoginScreen())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0771234567');
    await tester.tap(find.text('Send SMS code'));
    await tester.pumpAndSettle();
    expect(phone, '0771234567');
    expect(find.text('SMS verification code'), findsOneWidget);
    expect(find.text('Resend in 60s'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Verify and sign in'), 150, scrollable: find.byType(Scrollable).first);
    expect(find.text('Verify and sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SOS requires confirmation and keeps existing palette at narrow width', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: TeacherSosCard()))));
    await tester.tap(find.text('Send SOS to parents'));
    await tester.pumpAndSettle();
    expect(find.text('Send emergency SOS?'), findsOneWidget);
    expect(find.textContaining('assigned classes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Send emergency SOS?'), findsNothing);
  });
}
