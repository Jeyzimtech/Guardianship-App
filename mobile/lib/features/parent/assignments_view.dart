import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AssignmentsView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const AssignmentsView({super.key, this.child});

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  String _selectedFilter = 'All';

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
      'description': 'Document daily plant growth progress in project notebook.',
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

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'OVERDUE':
        return AppColors.error;
      case 'SUBMITTED':
        return AppColors.primary;
      case 'GRADED':
        return AppColors.primaryLight;
      default:
        return AppColors.textMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warningLight;
      case 'OVERDUE':
        return AppColors.errorLight;
      case 'SUBMITTED':
        return AppColors.softBlue;
      case 'GRADED':
        return AppColors.softBlue;
      default:
        return AppColors.softBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Pending', 'Submitted', 'Graded'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Homework Tasks',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${widget.child?['name'] ?? 'Student'} — ${widget.child?['class'] ?? 'Class'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSel = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.softBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSel ? AppColors.primary : AppColors.blueBorder,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Assignment List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(Icons.assignment_outlined,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No assignments in this category.',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      final status = item['status'] as String;
                      final subjectColor = item['subject_color'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Subject badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: subjectColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['subject'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: subjectColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusBg(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description'] as String,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 13,
                                        color: _statusColor(status)),
                                    const SizedBox(width: 5),
                                    Text(
                                      item['due_date'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item['score'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.softBlue,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.blueBorder),
                                    ),
                                    child: Text(
                                      'Score: ${item['score']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
