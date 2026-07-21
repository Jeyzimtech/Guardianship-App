import 'package:flutter/material.dart';
import '../student_management/student_management_screen.dart';
import '../user_management/user_management_screen.dart';
import '../school_management/school_management_screen.dart';
import '../teacher_management/teacher_management_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  static const primaryBlue = Color(0xFF3B5998);
  static const sidebarBg = Color(0xFFF5F6F7);
  static const borderColor = Color(0xFFD8D8D8);

  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == title;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0x143B5998) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? primaryBlue : Colors.transparent,
            width: 4.0,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          color: isSelected ? primaryBlue : const Color(0xFF64748B),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryBlue : const Color(0xFF1F2937),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          onTap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: sidebarBg,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: primaryBlue,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guardianship',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'PT Tech Platform',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF5B7BD5),
                  child: Text('AT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Tinotenda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                    Text('System Administrator', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),

          // 15 Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  title: 'Dashboard',
                  icon: Icons.space_dashboard_rounded,
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Students',
                  icon: Icons.school_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'Teachers',
                  icon: Icons.badge_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherManagementScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'Parents',
                  icon: Icons.people_alt_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'Classes',
                  icon: Icons.meeting_room_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchoolManagementScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'Attendance',
                  icon: Icons.fact_check_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Attendance module...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Reports',
                  icon: Icons.assessment_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Academic Reports...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Fees',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Fee Balances...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Payments',
                  icon: Icons.payment_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Payments Log...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Activities',
                  icon: Icons.sports_soccer_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Activities & Clubs...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Uniform Shop',
                  icon: Icons.checkroom_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Uniform Shop...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Messaging',
                  icon: Icons.forum_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Messaging...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Analytics',
                  icon: Icons.pie_chart_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to School Analytics...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Notifications',
                  icon: Icons.notifications_active_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Notifications...'))),
                ),
                _buildDrawerItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to System Settings...'))),
                ),
              ],
            ),
          ),

          // Drawer Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Guardianship © 2026', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                Text('v1.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
