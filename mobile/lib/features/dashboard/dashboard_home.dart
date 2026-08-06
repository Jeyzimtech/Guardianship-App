import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../common/app_drawer.dart';
import '../parent/parent_dashboard_view.dart';
import '../teacher/teacher_dashboard_view.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  static const primaryBlue = Color(0xFF3B5998);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.school_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              'Upenyu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                Positioned(right: 0, top: 0, child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFEF4444))),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3 Administrative Notifications'))),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'Dashboard'),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isTeacher) {
            return const TeacherDashboardView();
          }
          return const ParentDashboardView();
        },
      ),
    );
  }
}
