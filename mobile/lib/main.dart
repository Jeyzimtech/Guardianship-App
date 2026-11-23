import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/notification_provider.dart';
import 'core/push_notifications.dart';
import 'core/auth_provider.dart';
import 'core/role_guard.dart';
import 'core/student_provider.dart';
import 'core/subscription_provider.dart';
import 'features/parent/subscription_boundary.dart';
import 'core/app_colors.dart';
import 'features/common/editorial_widgets.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/legal/consent_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotifications.initialize();
  final apiClient = ApiClient();

  final subscription = SubscriptionProvider();
  apiClient.dio.interceptors.add(subscription.interceptor);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => subscription,
          update: (_, auth, access) => access!..bind(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, updates) => updates!..bind(auth),
        ),
      ],
      child: const PushNotificationListener(child: EduConectApp()),
    ),
  );
}

class EduConectApp extends StatelessWidget {
  const EduConectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => SubscriptionBoundary(child: child!),
      title: 'Edu Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Editorial.canvas,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
        ),
        fontFamily: 'Cabin',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          titleLarge: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.cardBorder, width: 1.0),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primaryLight,
              width: 1.8,
            ),
          ),
        ),
      ),
      home: const ConsentGate(child: AuthGate()),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      return const MobileRoleGuard(child: DashboardHome());
    } else {
      return const LoginScreen();
    }
  }
}
