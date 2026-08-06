import 'package:flutter/material.dart';

class AssignmentsView extends StatelessWidget {
  final Map<String, dynamic>? child;

  const AssignmentsView({super.key, this.child});

  static const primaryBlue = Color(0xFF3B5998);

  @override
  Widget build(BuildContext context) {
    final mockAssignments = [
      {
        'title': 'Fractions & Decimals Exercise Set 3',
        'subject': 'Mathematics',
        'description': 'Complete problems 1 to 15 on page 42 of Math workbook.',
        'due_date': 'Due in 2 Days (July 29)',
        'is_overdue': false,
      },
      {
        'title': 'Photosynthesis Observation Journal',
        'subject': 'Science',
        'description': 'Document daily plant growth progress in project notebook.',
        'due_date': 'OVERDUE (July 26)',
        'is_overdue': true,
      },
      {
        'title': 'Shona Comprehension & Vocabulary',
        'subject': 'Shona Language',
        'description': 'Read Chapter 4 and answer review questions 1-5.',
        'due_date': 'Due next Monday (Aug 2)',
        'is_overdue': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignments & Homework',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${child?['name'] ?? 'Student'} • Tasks & Homework Tracker',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockAssignments.length,
        itemBuilder: (context, index) {
          final item = mockAssignments[index];
          final isOverdue = item['is_overdue'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                width: isOverdue ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['subject'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['due_date'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] as String,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
