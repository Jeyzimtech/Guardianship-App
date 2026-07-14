import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'core/student_provider.dart';
import 'features/get_started_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiClient = ApiClient();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),
      ],
      child: const EduConectApp(),
    ),
  );
}

class EduConectApp extends StatelessWidget {
  const EduConectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const darkBlueColor = Color(0xFF0F1E36);
    const slateDarkColor = Color(0xFF1E293B);

    return MaterialApp(
      title: 'Edu+Conect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: darkBlueColor,
        scaffoldBackgroundColor: darkBlueColor,
        colorScheme: const ColorScheme.dark(
          primary: vanillaColor,
          secondary: vanillaColor,
          surface: slateDarkColor,
          background: darkBlueColor,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
      // Starts onboarding first
      home: const GetStartedScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isAuthenticated) {
      return const DashboardHome();
    } else {
      return const LoginScreen();
    }
  }
}
