import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/session.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/features/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sign out revokes the server token and returns to login from any screen', (tester) async {
    final api = ApiClient();
    String? logoutHeader;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (o.path == '/auth/login') {
            return h.resolve(Response(requestOptions: o, statusCode: 200, data: {
              'status': 'success',
              'token': 'tok-123',
              'user': {'id': 1, 'name': 'Parent', 'role': 'guardian'},
            }));
          }
          if (o.path == '/auth/logout') logoutHeader = o.headers['Authorization']?.toString();
          return h.resolve(Response(requestOptions: o, statusCode: 200, data: {'status': 'success'}));
        },
      ),
    );
    final auth = AuthProvider(api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => StudentProvider(api)),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('start'))),
      ),
    );
    expect(await tester.runAsync(() => auth.loginWithEmailPassword('parent@example.com', 'secret')), isTrue);

    // A screen pushed deep in the stack, like the profile tab after login.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => signOut(ctx), child: const Text('Log out')))),
      (_) => false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);
    expect(logoutHeader, 'Bearer tok-123');
  });
}
