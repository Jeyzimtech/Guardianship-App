import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../common/app_drawer.dart';
import '../student_management/student_management_screen.dart';
import '../user_management/user_management_screen.dart';
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
      body: RefreshIndicator(
        onRefresh: () => studentProvider.fetchDashboard(1),
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedSchool, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
                      const SizedBox(height: 2),
                      const Text('School Overview & Performance Dashboard', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryBlue,
                    child: Text('AT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 KPI Summary Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _buildKpiCard('Students', '1,250', Icons.school_rounded),
                  _buildKpiCard('Attendance', '95%', Icons.fact_check_rounded, valueColor: const Color(0xFF4CAF50), iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
                  _buildKpiCard('Outstanding', 'USD 24,000', Icons.file_present_rounded, valueColor: const Color(0xFFE74C3C), iconBg: const Color(0xFFFDEDEC), iconColor: const Color(0xFFE74C3C)),
                  _buildKpiCard('Unread', '15', Icons.forum_rounded, valueColor: const Color(0xFFF39C12), iconBg: const Color(0xFFFEF9E7), iconColor: const Color(0xFFF39C12)),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Modules Navigation
              const Text('Quick Management Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 10),
              _buildModuleCard(
                context,
                'Student Management',
                'Manage student roster, attendance & fee balances',
                Icons.school_rounded,
                primaryBlue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen())),
              ),
              const SizedBox(height: 10),
              _buildModuleCard(
                context,
                'Teacher Management',
                'Manage teachers, subject specialties & classes',
                Icons.badge_rounded,
                const Color(0xFF5B7BD5),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherManagementScreen())),
              ),
              const SizedBox(height: 10),
              _buildModuleCard(
                context,
                'School & Class Management',
                'Manage schools, academic years & class streams',
                Icons.domain_rounded,
                const Color(0xFF0284C7),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolManagementScreen())),
              ),
              const SizedBox(height: 10),
              _buildModuleCard(
                context,
                'User & Role Management',
                'Manage Admin, Teacher & Guardian accounts',
                Icons.manage_accounts_rounded,
                const Color(0xFF6B21A8),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
              ),
              const SizedBox(height: 20),

              // Recent Activity Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: const Border(
                    top: BorderSide(color: primaryBlue, width: 4.0),
                    left: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                        Icon(Icons.history_rounded, color: Color(0xFF6B7280), size: 20),
                      ],
                    ),
                    const Divider(height: 20, color: borderColor),
                    _buildActivityItem('Teacher Grace uploaded Grade 7 report card', '2 minutes ago'),
                    _buildActivityItem('Parent John Chewe paid school fees (USD 360)', '10 minutes ago'),
                    _buildActivityItem('Daily attendance completed for Grade 4 Gold', 'Today, 09:15 AM'),
                    _buildActivityItem('New student Alice Chewe registered', 'Yesterday'),
                  ],
                ),
              ),
            ],
          ),
        ),
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
