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
  String _selectedSchool = 'Hillside Primary School';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, size: 22),
            const SizedBox(width: 8),
            const Text('Edu+Conect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSchool,
                dropdownColor: primaryBlue,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'Hillside Primary School', child: Text('Hillside Primary')),
                  DropdownMenuItem(value: 'Hillside Preparatory', child: Text('Hillside Prep')),
                  DropdownMenuItem(value: 'Hillside Secondary', child: Text('Hillside Secondary')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSchool = val);
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.notifications_outlined),
                Positioned(right: 0, top: 0, child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE74C3C))),
              ],
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3 New Notifications'))),
          ),
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.chat_bubble_outline_rounded),
                Positioned(right: 0, top: 0, child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE74C3C))),
              ],
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('15 Unread Messages'))),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Log Out',
              onPressed: () => auth.logout(),
            ),
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
