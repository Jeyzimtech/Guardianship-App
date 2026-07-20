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
    const primaryColor = Color(0xFF05D099); // Vibrant Mint Green
    const darkTealColor = Color(0xFF0B5549); // Dark Teal Accent
    const backgroundColor = Color(0xFFFFFFFF); // Pure clean white
    const surfaceColor = Color(0xFFF7F9FA); // Soft container tint
    const textPrimaryColor = Color(0xFF0B5549); // Dark Teal text
    const textSecondaryColor = Color(0xFF6B7280); // Gray text
    const borderColor = Color(0xFFE5E7EB); // Soft light border

    return MaterialApp(
      title: 'Edu+Conect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: darkTealColor,
          surface: backgroundColor,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimaryColor),
          bodyMedium: TextStyle(color: textPrimaryColor),
          titleLarge: TextStyle(color: darkTealColor, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: darkTealColor,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: darkTealColor),
          titleTextStyle: TextStyle(color: darkTealColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkTealColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTealColor,
            side: const BorderSide(color: darkTealColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF3F4F6),
          labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
          hintStyle: TextStyle(color: textSecondaryColor.withValues(alpha: 0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
