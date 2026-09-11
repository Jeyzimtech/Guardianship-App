import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/editorial_widgets.dart';
import '../common/app_drawer.dart';
import '../parent/parent_dashboard_view.dart';
import '../parent/learning_journal_view.dart';
import '../parent/messaging_view.dart';
import '../parent/guardian_profile_view.dart';
import '../dashboard/announcements_view.dart';

/// Parent shell with AppBar + BottomNavigationBar
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _currentIndex = 0;

  static final Map<String, dynamic> _defaultChild = {
    'name': 'Alice Chewe',
    'class': 'Grade 4 Gold',
    'school': 'Hillside Primary School',
  };

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final child = (studentProvider.selectedStudent != null
        ? studentProvider.selectedStudent as Map<String, dynamic>
        : _defaultChild);

    _pages = [
      const ParentDashboardView(),
      const AnnouncementsView(),
      LearningJournalView(child: child),
      const MessagingView(),
      GuardianProfileView(child: child),
    ];
  }

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
          onTap: (i) => setState(() => _currentIndex = i),
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
              icon: AppIcon(AppSymbol.message),
              activeIcon: AppIcon(AppSymbol.message),
              label: 'Notices',
            ),
            BottomNavigationBarItem(
              icon: AppIcon(AppSymbol.report),
              activeIcon: AppIcon(AppSymbol.report),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: AppIcon(AppSymbol.message),
              activeIcon: AppIcon(AppSymbol.message),
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
