import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../profile/profile_view.dart';
import '../parent/uniform_marketplace_view.dart';
import '../parent/learning_journal_view.dart';
import '../parent/behaviour_view.dart';
import '../parent/assignments_view.dart';
import '../dashboard/payments_view.dart';
import '../dashboard/announcements_view.dart';
import '../dashboard/attendance_view.dart';

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
          // Drawer Header with App Logo
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: primaryBlue,
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edu+Conect',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Guardianship Portal',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clickable User Info Bar -> Navigate to Profile
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isTeacher = auth.isTeacher;
              final name = auth.user?['name'] ?? (isTeacher ? 'Teacher Grace' : 'Guardian John Chewe');
              final initials = isTeacher ? 'TG' : 'JC';

              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileView()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isTeacher ? const Color(0xFF5B7BD5) : const Color(0xFF3B5998),
                        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
                            Text(isTeacher ? 'Class Teacher' : 'My Profile', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
                    ],
                  ),
                ),
              );
            },
          ),

          // Role-Scoped Menu Items List
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final isTeacher = auth.isTeacher;

                return ListView(
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
                      title: 'My Profile',
                      icon: Icons.person_outline_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      ),
                    ),
                    if (!isTeacher) ...[
                      _buildDrawerItem(
                        context,
                        title: 'Uniform Store',
                        icon: Icons.shopping_bag_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UniformMarketplaceView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Learning Journal',
                        icon: Icons.auto_stories_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LearningJournalView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Fee Payments',
                        icon: Icons.account_balance_wallet_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentsView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Behaviour & Merits',
                        icon: Icons.star_rate_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BehaviourView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Homework Tasks',
                        icon: Icons.assignment_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AssignmentsView()),
                        ),
                      ),
                    ] else ...[
                      _buildDrawerItem(
                        context,
                        title: 'Class Attendance',
                        icon: Icons.fact_check_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendanceView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Post Learning Entry',
                        icon: Icons.add_a_photo_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LearningJournalView()),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Class Assignments',
                        icon: Icons.assignment_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AssignmentsView()),
                        ),
                      ),
                    ],
                    _buildDrawerItem(
                      context,
                      title: 'Notifications',
                      icon: Icons.notifications_active_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnnouncementsView()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Drawer Footer with Logout Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close drawer
                    await auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                  label: const Text(
                    'LOG OUT',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
