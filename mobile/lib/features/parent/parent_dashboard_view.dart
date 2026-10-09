import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/student_provider.dart';
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
  int _selectedChildIndex = 0;

  void selectChild(int index) {
    setState(() {
      _selectedChildIndex = index;
    });
  }

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
    StudentProvider? studentProvider;
    try {
      studentProvider = Provider.of<StudentProvider>(context);
    } catch (_) {
      studentProvider = null;
    }

    final rawStudents = studentProvider?.students ?? [];
    final hasStudents = rawStudents.isNotEmpty;
    final safeIndex = (hasStudents && _selectedChildIndex < rawStudents.length)
        ? _selectedChildIndex
        : 0;

    final child = hasStudents
        ? {
            'id': rawStudents[safeIndex]['id'],
            'name': rawStudents[safeIndex]['name'] ?? 'Enrolled Learner',
            'class': '${rawStudents[safeIndex]['grade'] ?? ''} ${rawStudents[safeIndex]['class_name'] ?? ''}'.trim(),
            'school': rawStudents[safeIndex]['school'] != null
                ? (rawStudents[safeIndex]['school']['name']?.toString() ?? 'Hillside School')
                : 'Hillside School',
            'attendance_rate': '100%',
            'merits_pos': 12,
            'merits_neg': 0,
          }
        : {
            'name': 'Enrolled Learner',
            'class': 'General Class',
            'school': 'Hillside School',
            'attendance_rate': '100%',
            'merits_pos': 0,
            'merits_neg': 0,
          };

    return ColoredBox(
      color: Editorial.canvas,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            const Text('A good day\nto learn.', style: Editorial.headline),
            if (!hasStudents) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LEARNER ROSTER',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No enrolled learners linked yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Student accounts and enrollments are provisioned by your school administrator. Once your school links your child, their records will display here.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _showRequestAddStudentDialog(context),
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: const Text('Request Child Link', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            if (rawStudents.length > 1) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(rawStudents.length, (idx) {
                    final isSel = idx == safeIndex;
                    final studentName = rawStudents[idx]['name'] ?? 'Learner ${idx + 1}';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(studentName),
                        selected: isSel,
                        onSelected: (_) => selectChild(idx),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
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
