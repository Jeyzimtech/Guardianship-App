import 'package:flutter/material.dart';

class AssignmentsView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const AssignmentsView({super.key, this.child});

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  static const primaryBlue = Color(0xFF3B5998);
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _mockAssignments = [
    {
      'title': 'Fractions & Decimals Exercise Set 3',
      'subject': 'MATHEMATICS',
      'subject_color': Color(0xFF3B5998),
      'description': 'Complete problems 1 to 15 on page 42 of Math workbook.',
      'due_date': 'Due 22 Aug 2026',
      'status': 'PENDING',
      'score': null,
    },
    {
      'title': 'Photosynthesis Observation Journal',
      'subject': 'SCIENCE',
      'subject_color': Color(0xFF059669),
      'description': 'Document daily plant growth progress in project notebook.',
      'due_date': 'Overdue — 26 Jul 2026',
      'status': 'OVERDUE',
      'score': null,
    },
    {
      'title': 'Shona Comprehension & Vocabulary',
      'subject': 'SHONA',
      'subject_color': Color(0xFF7C3AED),
      'description': 'Read Chapter 4 and answer review questions 1-5.',
      'due_date': 'Due 2 Aug 2026',
      'status': 'SUBMITTED',
      'score': null,
    },
    {
      'title': 'English Essay — My Community',
      'subject': 'ENGLISH',
      'subject_color': Color(0xFFD97706),
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
        return const Color(0xFFF59E0B);
      case 'OVERDUE':
        return const Color(0xFFEF4444);
      case 'SUBMITTED':
        return primaryBlue;
      case 'GRADED':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFEF3C7);
      case 'OVERDUE':
        return const Color(0xFFFEE2E2);
      case 'SUBMITTED':
        return const Color(0xFFEFF6FF);
      case 'GRADED':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Pending', 'Submitted', 'Graded'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
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
            color: Colors.white,
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
                          color: isSel ? primaryBlue : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSel ? primaryBlue : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

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
                            color: primaryBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(Icons.assignment_outlined,
                              color: primaryBlue, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No assignments in this category.',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colored top accent strip
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: subjectColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
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
                                        color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['description'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                        height: 1.3),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 12,
                                              color: _statusColor(status)),
                                          const SizedBox(width: 4),
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
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Score: ${item['score']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
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
