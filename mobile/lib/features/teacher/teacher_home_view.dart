import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../common/editorial_widgets.dart';
import 'teacher_dashboard_view.dart';
import '../parent/learning_journal_view.dart';
import '../parent/assignments_view.dart';

/// Teacher overview using the shared Editorial design.
class TeacherHomeView extends StatefulWidget {
  const TeacherHomeView({super.key});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  final String _selectedClass = 'Grade 4A';

  final List<Map<String, dynamic>> _schedule = [
    {
      'time': '08:30',
      'subject': 'Homeroom & Roll Call',
      'duration': '30 min',
      'done': true,
    },
    {
      'time': '09:00',
      'subject': 'Mathematics — Fractions',
      'duration': '60 min',
      'done': true,
    },
    {
      'time': '10:00',
      'subject': 'Science — Photosynthesis Lab',
      'duration': '60 min',
      'done': false,
    },
    {
      'time': '11:00',
      'subject': 'Break / Supervision Duty',
      'duration': '30 min',
      'done': false,
    },
    {
      'time': '11:30',
      'subject': 'English — Essay Writing',
      'duration': '60 min',
      'done': false,
    },
    {
      'time': '13:00',
      'subject': 'Sports Afternoon — Athletics',
      'duration': '90 min',
      'done': false,
    },
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todayLabel() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teacherName = auth.user?['name'] ?? 'Mrs. Davis';
    final students = {'Grade 4A': 32, 'Grade 5B': 28, 'Grade 6C': 30};
    return ColoredBox(
      color: Editorial.canvas,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text(
              '${_greeting()}, $teacherName',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Make room\nfor learning.', style: Editorial.headline),
            const SizedBox(height: 28),
            EditorialFeature(
              eyebrow: 'YOUR CLASSROOM',
              title: 'Start with attendance',
              subtitle: 'A thoughtful start to your school day.',
              onTap: () => _open(const TeacherDashboardView()),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: EditorialMetric(
                    value: '${students[_selectedClass]}',
                    label: 'Students',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EditorialMetric(
                    value:
                        '${_schedule.where((item) => item['done'] != true).length}',
                    label: 'Sessions ahead',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Teaching essentials', style: Editorial.section),
            const SizedBox(height: 16),
            EditorialLink(
              title: 'Learning journal',
              subtitle: 'Share learning moments with families',
              onTap: () => _open(const LearningJournalView()),
            ),
            EditorialLink(
              title: 'Homework',
              subtitle: 'Review class homework tasks',
              onTap: () => _open(const AssignmentsView()),
            ),
            const SizedBox(height: 20),
            const Text('Today’s schedule', style: Editorial.section),
            const SizedBox(height: 8),
            Text(
              _todayLabel(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < _schedule.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: 20, endIndent: 20),
                    _scheduleItem(_schedule[index]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleItem(Map<String, dynamic> item) {
    final done = item['done'] == true;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['time'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item['subject'],
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item['duration'],
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => item['done'] = !done),
                child: Text(done ? 'Completed · Undo' : 'Mark complete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
