import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../teacher/create_assignment_page.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class AssignmentsView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const AssignmentsView({super.key, this.child});

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  String _selectedFilter = 'All';
  List<dynamic> _classes = [];
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final student =
        widget.child?['id'] ??
        context.read<StudentProvider?>()?.selectedStudent?['id'];
    if (!auth.isTeacher && student == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _mockAssignments.clear();
    });
    try {
      final response = await auth.apiClient.dio.get(
        auth.isTeacher ? '/teacher/assignments' : '/assignments/$student',
      );
      if (response.data['status'] != 'success') throw StateError('Load failed');
      final List<dynamic> items = auth.isTeacher
          ? response.data['data']
          : response.data['data']['all'];
      if (!mounted) return;
      setState(() {
        _classes = response.data['classes'] ?? [];
        _mockAssignments.addAll(
          items.map(
            (a) => <String, dynamic>{
              'title': a['title'],
              'subject': a['subject_name'] ?? 'Assignment',
              'description': a['description'] ?? '',
              'due_date': 'Due ${a['due_date']}',
              'status': auth.isTeacher
                  ? 'PUBLISHED'
                  : (DateTime.tryParse(
                              a['due_date'] ?? '',
                            )?.isBefore(DateUtils.dateOnly(DateTime.now())) ==
                            true
                        ? 'OVERDUE'
                        : 'PENDING'),
            },
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load assignments. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAssignmentPage(
          api: context.read<AuthProvider>().apiClient,
          classes: _classes,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment created.')));
      await _load();
    }
  }

  final List<Map<String, dynamic>> _mockAssignments = [
    {
      'title': 'Fractions & Decimals Exercise Set 3',
      'subject': 'MATHEMATICS',
      'subject_color': AppColors.primary,
      'description': 'Complete problems 1 to 15 on page 42 of Math workbook.',
      'due_date': 'Due 22 Aug 2026',
      'status': 'PENDING',
      'score': null,
    },
    {
      'title': 'Photosynthesis Observation Journal',
      'subject': 'SCIENCE',
      'subject_color': AppColors.primaryLight,
      'description':
          'Document daily plant growth progress in project notebook.',
      'due_date': 'Overdue — 26 Jul 2026',
      'status': 'OVERDUE',
      'score': null,
    },
    {
      'title': 'Shona Comprehension & Vocabulary',
      'subject': 'SHONA',
      'subject_color': AppColors.primaryDark,
      'description': 'Read Chapter 4 and answer review questions 1-5.',
      'due_date': 'Due 2 Aug 2026',
      'status': 'SUBMITTED',
      'score': null,
    },
    {
      'title': 'English Essay — My Community',
      'subject': 'ENGLISH',
      'subject_color': AppColors.primaryAccent,
      'description': 'Write a 3-paragraph descriptive essay on your community.',
      'due_date': 'Graded — 15 Jul 2026',
      'status': 'GRADED',
      'score': '18/20',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'All') return _mockAssignments;
    return _mockAssignments
        .where((a) => a['status'] == _selectedFilter.toUpperCase())
        .toList();
  }

  Color _statusColor(String status) => switch (status) {
    'OVERDUE' => const Color(0xFFB91C1C),
    'PENDING' => const Color(0xFF92400E),
    'GRADED' => const Color(0xFF047857),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final teacher = context.watch<AuthProvider>().isTeacher;
    final remaining = _mockAssignments
        .where((a) => a['status'] == 'PENDING' || a['status'] == 'OVERDUE')
        .length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Homework'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeading(
              title: 'Homework',
              subtitle: widget.child == null
                  ? 'A clear view of assignments and progress.'
                  : '${widget.child!['name']} · ${widget.child!['class'] ?? 'Assignments'}',
              symbol: AppSymbol.report,
            ),
            if (teacher) ...[
              FilledButton.icon(
                onPressed: _loading || _error != null ? null : _create,
                icon: const Icon(Icons.add),
                label: const Text('Create assignment'),
              ),
              const SizedBox(height: 20),
            ],
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              PageCard(
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            PageCard(
              color: AppColors.softBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher ? 'CLASS ASSIGNMENTS' : 'YOUR NEXT STEPS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    teacher
                        ? '${_mockAssignments.length} published assignments'
                        : '$remaining tasks to complete',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    teacher
                        ? 'Create clear instructions and keep your class on track.'
                        : 'Check due dates and make time for a little progress each day.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PageFilters(
              labels: teacher
                  ? const ['All', 'Published']
                  : const ['All', 'Pending', 'Overdue', 'Submitted', 'Graded'],
              selected: _selectedFilter,
              onSelected: (value) => setState(() => _selectedFilter = value),
            ),
            const SizedBox(height: 20),
            if (!_loading && _error == null && _filtered.isEmpty)
              const PageEmpty(
                title: 'All clear here',
                message:
                    'No assignments match this status. Choose another filter to see more.',
              ),
            for (final item in _filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PageBadge(item['subject']),
                          PageBadge(
                            item['status'],
                            color: _statusColor(item['status']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['description'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item['due_date'],
                            style: TextStyle(
                              fontSize: 13,
                              color: _statusColor(item['status']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item['score'] != null)
                            PageBadge(
                              'Score ${item['score']}',
                              color: const Color(0xFF047857),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
