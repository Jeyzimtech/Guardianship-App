import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/main.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/core/subscription_provider.dart';
import 'package:guardianship/core/legal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads get started page smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({Legal.acceptedKey: Legal.version});
    final apiClient = ApiClient();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
          ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: const EduConectApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Login Screen is present
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
