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
    const oldDarkBlueColor = Color(0xFF002D62);
    const cardBgColor = Color(0xFFFFFDF0);

    return MaterialApp(
      title: 'Edu+Conect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: oldDarkBlueColor,
        scaffoldBackgroundColor: vanillaColor,
        colorScheme: const ColorScheme.light(
          primary: oldDarkBlueColor,
          secondary: oldDarkBlueColor,
          surface: cardBgColor,
          background: vanillaColor,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: cardBgColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: oldDarkBlueColor, width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: oldDarkBlueColor),
          bodyMedium: TextStyle(color: oldDarkBlueColor),
          titleLarge: TextStyle(color: oldDarkBlueColor, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: oldDarkBlueColor,
          foregroundColor: vanillaColor,
          elevation: 2,
          iconTheme: IconThemeData(color: vanillaColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: oldDarkBlueColor,
            foregroundColor: vanillaColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: oldDarkBlueColor),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: oldDarkBlueColor,
            side: const BorderSide(color: oldDarkBlueColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBgColor,
          labelStyle: const TextStyle(color: oldDarkBlueColor),
          hintStyle: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: oldDarkBlueColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: oldDarkBlueColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: oldDarkBlueColor, width: 2.5),
          ),
        ),
      ),
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
