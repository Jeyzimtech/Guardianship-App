import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../common/editorial_widgets.dart';
import 'teacher_dashboard_view.dart';
import 'teacher_publish_page.dart';
import '../parent/learning_journal_view.dart';
import '../parent/assignments_view.dart';

/// Teacher overview using the shared Editorial design.
class TeacherHomeView extends StatefulWidget {
  const TeacherHomeView({super.key});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  List<Map<String, dynamic>> _classes = [];
  int? _students;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().apiClient;
      final responses = await Future.wait([
        api.dio.get('/students'),
        api.dio.get('/teacher/assignments'),
      ]);
      if (!mounted) return;
      setState(() {
        _students = (responses[0].data['students'] as List? ?? []).length;
        _classes = (responses[1].data['classes'] as List? ?? [])
            .map((c) => Map<String, dynamic>.from(c))
            .toList();
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not load your classroom. Pull down to try again.',
        );
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teacherName = auth.user?['name'] ?? 'Teacher';
    return ColoredBox(
      color: Editorial.canvas,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
                      value: _students?.toString() ?? '—',
                      label: 'Students',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EditorialMetric(
                      value: '${_classes.map((c) => c['id']).toSet().length}',
                      label: 'Assigned classes',
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
                title: 'Upload a report',
                subtitle: 'Share a report with the student’s family',
                onTap: () => _open(const TeacherPublishPage(report: true)),
              ),
              EditorialLink(
                title: 'Homework',
                subtitle: 'Review class homework tasks',
                onTap: () => _open(const AssignmentsView()),
              ),
              const SizedBox(height: 20),
              const Text('Your assigned classes', style: Editorial.section),
              const SizedBox(height: 12),
              if (_error != null) Text(_error!),
              if (_classes.isEmpty && _error == null)
                const Text(
                  'Your school administrator will assign your classes here.',
                ),
              for (final schoolClass in _classes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${schoolClass['grade']} · ${schoolClass['class_name']}',
                  ),
                  subtitle: Text(
                    schoolClass['pivot']?['subject_name']?.toString() ??
                        'General',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
