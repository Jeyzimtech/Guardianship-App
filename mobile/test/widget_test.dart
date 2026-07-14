import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/main.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads get started page smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
          ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),
        ],
        child: const EduConectApp(),
      ),
    );

    // Verify Welcome title is present
    expect(find.text('Welcome to Edu+Conect'), findsOneWidget);
  });
}
