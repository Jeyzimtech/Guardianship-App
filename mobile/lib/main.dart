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
    // Global Color Palette Specifications
    const primaryBlue = Color(0xFF3B5998); // Facebook Blue
    const secondaryBlue = Color(0xFF5B7BD5); // Secondary Blue
    const backgroundColor = Color(0xFFFFFFFF); // Pitch White Background
    const surfaceColor = Color(0xFFF5F6F7); // Sidebar / Surface Tint
    const borderColor = Color(0xFFD8D8D8); // Card & Table Border
    const textPrimaryColor = Color(0xFF1F2937); // Text Dark
    const textSecondaryColor = Color(0xFF6B7280); // Text Muted

    return MaterialApp(
      title: 'Guardianship App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: secondaryBlue,
          surface: surfaceColor,
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 14),
          bodyMedium: TextStyle(color: textPrimaryColor, fontSize: 14),
          titleLarge: TextStyle(color: primaryBlue, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: primaryBlue, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 13),
          hintStyle: TextStyle(color: textSecondaryColor.withValues(alpha: 0.6), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: secondaryBlue, width: 1.5),
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
