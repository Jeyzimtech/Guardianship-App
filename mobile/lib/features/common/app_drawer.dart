import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/notification_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../teacher/teacher_publish_page.dart';
import '../parent/assignments_view.dart';
import '../dashboard/attendance_view.dart';
import '../../core/session.dart';
import 'documents_view.dart';

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
    final updates = context.watch<NotificationProvider?>();
    final category = title == 'Learning Journal'
        ? 'journal'
        : title == 'Notifications' || title == 'Announcements'
        ? 'notices'
        : title == 'Messages'
        ? 'messages'
        : '';
    final unread = updates?.count(category) ?? 0;

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
        trailing: unread > 0
            ? Badge(
                label: Text(unread > 99 ? '99+' : '$unread'),
                backgroundColor: const Color(0xFFEF1524),
              )
            : null,
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
                  'assets/e.png',
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
                        'Edu Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                    if (!isTeacher) ...[
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
                            builder: (_) => const TeacherPublishPage(),
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        title: 'Upload a report',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TeacherPublishPage(report: true),
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
                      title: 'School documents',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DocumentsView(),
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
                  onPressed: () => signOut(context),
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
