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
              'Edu+Conect',
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
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user;
              final name = user?['name'] ?? (auth.isTeacher ? 'Teacher Grace' : 'John Chewe');
              final role = auth.isTeacher ? 'Teacher' : 'Parent / Guardian';
              final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8.0),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.white24, width: 1)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Text(
                              initials.isEmpty ? 'U' : initials,
                              style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                role,
                                style: const TextStyle(color: Colors.white70, fontSize: 9),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => auth.logout(),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
