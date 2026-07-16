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
    const primaryColor = Color(0xFF0047AB); // Cobalt Blue
    const accentColor = Color(0xFF0047AB); // Cobalt Blue
    const backgroundColor = Color(0xFFEFEAE2); // Sand
    const surfaceColor = Colors.white;
    const textPrimaryColor = Color(0xFF1F2937); // Slate 800
    const textSecondaryColor = Color(0xFF4B5563); // Slate 600
    const borderColor = Color(0xFFD4CFC7); // Warm grey border

    return MaterialApp(
      title: 'Edu+Conect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimaryColor),
          bodyMedium: TextStyle(color: textPrimaryColor),
          titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: borderColor, width: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
          hintStyle: TextStyle(color: textSecondaryColor.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accentColor, width: 1.5),
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
