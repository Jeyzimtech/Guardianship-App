import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../profile/profile_view.dart';
import '../parent/uniform_marketplace_view.dart';
import '../parent/learning_journal_view.dart';
import '../parent/behaviour_view.dart';
import '../parent/assignments_view.dart';
import '../dashboard/announcements_view.dart';
import '../dashboard/attendance_view.dart';
import '../auth/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  static const primaryBlue = AppColors.primary;
  static const sidebarBg = AppColors.surface;
  static const borderColor = AppColors.cardBorder;

  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == title;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.softBlue : Colors.transparent,
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
        leading: AppIcon(
          symbolForFeature(title),
          color: isSelected ? primaryBlue : AppColors.textMuted,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryBlue : AppColors.textPrimary,
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

                      onTap: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                    ),
                    _buildDrawerItem(
                      context,
                      title: 'My Profile',

                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      ),
                    ),
                    if (!isTeacher) ...[
                      _buildDrawerItem(
                        context,
                        title: 'Uniform Store',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UniformMarketplaceView(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Learning Journal',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningJournalView(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Behaviour & Merits',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BehaviourView(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Homework Tasks',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssignmentsView(),
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildDrawerItem(
                        context,
                        title: 'Class Attendance',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceView(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Post Learning Entry',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningJournalView(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Class Assignments',

                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssignmentsView(),
                          ),
                        ),
                      ),
                    ],
                    _buildDrawerItem(
                      context,
                      title: 'Notifications',

                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementsView(),
                        ),
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
                    final studentProvider = Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    );
                    studentProvider.clearData();
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'LOG OUT',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
