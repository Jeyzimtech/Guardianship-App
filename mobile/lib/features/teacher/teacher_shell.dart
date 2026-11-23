import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/editorial_widgets.dart';
import '../common/app_drawer.dart';
import '../common/unread_icon.dart';
import '../teacher/teacher_dashboard_view.dart';
import '../teacher/teacher_home_view.dart';
import '../parent/messaging_view.dart';
import '../parent/learning_journal_view.dart';
import '../profile/profile_view.dart';

/// Teacher shell with AppBar + BottomNavigationBar
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;
  // Tabs are built on first visit so startup only loads the home screen.
  final Set<int> _visited = {0};
  final Map<int, int> _visits = {};

  static const List<Widget> _allPages = [
    TeacherHomeView(),
    TeacherDashboardView(),
    LearningJournalView(),
    MessagingView(),
    ProfileView(),
  ];

  List<Widget> get _pages => [
    for (var i = 0; i < _allPages.length; i++)
      _visited.contains(i)
          ? KeyedSubtree(key: ValueKey('$i-${_visits[i]}'), child: _allPages[i])
          : const SizedBox.shrink(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Editorial.canvas,
      drawer: const AppDrawer(currentRoute: 'Dashboard'),
      appBar: AppBar(
        backgroundColor: Editorial.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Edu+Conect',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() {
            if (_currentIndex != i) _visits[i] = (_visits[i] ?? 0) + 1;
            _currentIndex = i;
            _visited.add(i);
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: AppIcon(AppSymbol.home),
              activeIcon: AppIcon(AppSymbol.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AppIcon(AppSymbol.school),
              activeIcon: AppIcon(AppSymbol.school),
              label: 'Classroom',
            ),
            BottomNavigationBarItem(
              icon: UnreadIcon(AppSymbol.report, 'journal'),
              activeIcon: UnreadIcon(AppSymbol.report, 'journal'),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: UnreadIcon(AppSymbol.message, 'messages'),
              activeIcon: UnreadIcon(AppSymbol.message, 'messages'),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: AppIcon(AppSymbol.profile),
              activeIcon: AppIcon(AppSymbol.profile),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
