import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../common/app_drawer.dart';
import '../parent/parent_dashboard_view.dart';
import '../teacher/teacher_dashboard_view.dart';
import '../student_management/student_management_screen.dart';
import '../school_management/school_management_screen.dart';
import '../teacher_management/teacher_management_screen.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  static const primaryBlue = Color(0xFF3B5998);
  static const borderColor = Color(0xFFD8D8D8);
  String _selectedSchool = 'Hillside Primary School';

  Widget _buildKpiCard(String title, String value, IconData icon, {Color? valueColor, Color? iconBg, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border(
          top: BorderSide(color: primaryBlue, width: 4.0),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF1F2937))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg ?? const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor ?? primaryBlue, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

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

  Widget _buildActivityItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
