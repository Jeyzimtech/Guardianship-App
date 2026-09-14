import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'student_provider.dart';
import '../features/auth/login_screen.dart';

class MobileRoleGuard extends StatelessWidget {
  final Widget child;

  const MobileRoleGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Check if role is admin or website_admin
    if (user != null && (user['role'] == 'admin' || user['role'] == 'website_admin')) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 42,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Web Portal Access Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'The mobile application is designed exclusively for Teachers and Parents/Students.\n\nAdministrators must log in using the Web Admin Portal on a web browser.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                      studentProvider.clearData();
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Return to Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5998),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
