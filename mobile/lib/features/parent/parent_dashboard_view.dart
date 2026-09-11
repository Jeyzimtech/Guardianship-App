import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../common/editorial_widgets.dart';
import '../dashboard/attendance_view.dart';
import '../dashboard/reports_view.dart';
import '../dashboard/announcements_view.dart';
import 'learning_journal_view.dart';
import 'behaviour_view.dart';
import 'assignments_view.dart';
import 'sms_alerts_log_view.dart';
import 'messaging_view.dart';
import 'uniform_marketplace_view.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  // Unified Guardian Account Children
  int _selectedChildIndex = 0;

  void selectChild(int index) {
    if (index >= 0 && index < _mockChildren.length) {
      setState(() {
        _selectedChildIndex = index;
      });
    }
  }

  final List<Map<String, dynamic>> _mockChildren = [
    {
      'name': 'Alice Chewe',
      'class': 'Grade 4 Gold',
      'tier': 'primary',
      'school': 'Hillside Primary School',
      'homeroom_teacher': 'Teacher Grace',
      'attendance_rate': '96%',
      'days_present': 58,
      'total_days': 60,
      'z_score': '+0.45 SD',
      'velocity_status': 'On Track for A-Level',
      'merits_pos': 14,
      'merits_neg': 1,
    },
    {
      'name': 'Timothy Chewe',
      'class': 'ECD B - Sunflowers',
      'tier': 'preparatory',
      'school': 'Hillside Preparatory (ECD)',
      'caregiver': 'Amai Tendai',
      'attendance_rate': '98%',
      'days_present': 59,
      'total_days': 60,
      'z_score': '+0.20 SD',
      'velocity_status': 'On Track for Preparatory',
      'merits_pos': 8,
      'merits_neg': 0,
    },
    {
      'name': 'Brian Chewe',
      'class': 'Form 3 Blue',
      'tier': 'secondary',
      'school': 'Hillside Secondary School',
      'tutor': 'Mr. Moyo',
      'attendance_rate': '94%',
      'days_present': 56,
      'total_days': 60,
      'z_score': '+0.60 SD',
      'velocity_status': 'On Track for O-Level Distinction',
      'merits_pos': 18,
      'merits_neg': 2,
    },
  ];

  void _showRequestAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final schoolController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Student to Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'School Admin Verification Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blueBorder),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For student security, additional children are added and linked exclusively by the School Administrator. Submit your request below for admin approval.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Full Name or ID Number',
                hintText: 'e.g. Tendai Chewe (Grade 1)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                hintText: 'e.g. Hillside Primary School',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Relationship / Notes to Admin',
                hintText: 'e.g. Parent / Legal Guardian',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter student name or ID.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Link request for "$name" submitted to School Admin! You will be notified once approved.',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Submit Link Request to Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _mockChildren[_selectedChildIndex];
    return ColoredBox(
      color: Editorial.canvas,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            DropdownButton<int>(
              value: _selectedChildIndex,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'Cabin',
                color: AppColors.primaryDark,
                fontSize: 14,
              ),
              underline: const Divider(color: AppColors.cardBorder),
              items: _mockChildren
                  .asMap()
                  .entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        '${e.value['name']} / ${e.value['class']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) selectChild(value);
              },
            ),
            const SizedBox(height: 24),
            const Text('A good day\nto learn.', style: Editorial.headline),
            const SizedBox(height: 28),
            EditorialFeature(
              eyebrow: 'TODAY AT SCHOOL',
              title: 'Learning in focus',
              subtitle: 'Your child’s day, at a glance.',
              onTap: () => _open(LearningJournalView(child: child)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: EditorialMetric(
                    value: child['attendance_rate'],
                    label: 'Attendance',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EditorialMetric(
                    value: '${child['merits_pos']}',
                    label: 'Positive merits',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Latest from school', style: Editorial.section),
            const SizedBox(height: 16),
            EditorialLink(
              title: 'School notices',
              subtitle: 'News, events and updates from your school',
              onTap: () => _open(const AnnouncementsView()),
            ),
            EditorialLink(
              title: 'Teacher conversations',
              subtitle: 'Keep in touch about your child’s progress',
              onTap: () => _open(const MessagingView()),
            ),
            const SizedBox(height: 20),
            const Text('Learning & progress', style: Editorial.section),
            const SizedBox(height: 16),
            EditorialLink(
              title: 'Learning journal',
              subtitle: 'Classroom moments and teacher feedback',
              onTap: () => _open(LearningJournalView(child: child)),
            ),
            EditorialLink(
              title: 'Homework',
              subtitle: 'Assignments and upcoming due dates',
              onTap: () => _open(AssignmentsView(child: child)),
            ),
            EditorialLink(
              title: 'Attendance',
              subtitle: 'Review your child’s attendance record',
              onTap: () => _open(const AttendanceView()),
            ),
            EditorialLink(
              title: 'Behaviour & merits',
              subtitle: 'Achievements and wellbeing',
              onTap: () => _open(BehaviourView(child: child)),
            ),
            EditorialLink(
              title: 'Academic reports',
              subtitle: 'Review term reports and progress',
              onTap: () => _open(const ReportsView()),
            ),
            const SizedBox(height: 20),
            const Text('School essentials', style: Editorial.section),
            const SizedBox(height: 16),
            EditorialLink(
              title: 'SMS history',
              subtitle: 'Review school text messages',
              onTap: () => _open(const SmsAlertsLogView()),
            ),
            EditorialLink(
              title: 'Uniform store',
              subtitle: 'Browse school essentials',
              onTap: () => _open(UniformMarketplaceView(child: child)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _showRequestAddStudentDialog(context),
              child: const Text('Link another child'),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
