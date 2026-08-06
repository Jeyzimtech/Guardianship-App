import 'package:flutter/material.dart';

class BehaviourView extends StatelessWidget {
  final Map<String, dynamic>? child;

  const BehaviourView({super.key, this.child});

  static const primaryBlue = Color(0xFF3B5998);

  @override
  Widget build(BuildContext context) {
    final mockIncidents = [
      {
        'polarity': 'positive',
        'category': 'Excellence in Mathematics',
        'note': 'Scored highest mark in mid-term mental arithmetic speed quiz.',
        'author': 'Teacher Grace',
        'date': '2 days ago',
      },
      {
        'polarity': 'positive',
        'category': 'Helpfulness & Leadership',
        'note': 'Assisted fellow class members in organizing classroom library books.',
        'author': 'Teacher Grace',
        'date': '5 days ago',
      },
      {
        'polarity': 'negative',
        'category': 'Late Homework Submission',
        'note': 'Science observation journal submitted 1 day past due date.',
        'author': 'Teacher Grace',
        'date': '2 weeks ago',
      },
    ];

    final positiveCount = mockIncidents.where((i) => i['polarity'] == 'positive').length;
    final negativeCount = mockIncidents.where((i) => i['polarity'] == 'negative').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Behaviour & Merits Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${child['name']} • Conduct Snapshot',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$positiveCount',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Positive Merits',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$negativeCount',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Conduct Alerts',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Incident History & Merits Log',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockIncidents.length,
              itemBuilder: (context, index) {
                final incident = mockIncidents[index];
                final isPositive = incident['polarity'] == 'positive';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        child: Icon(
                          isPositive ? Icons.thumb_up_rounded : Icons.warning_rounded,
                          color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    incident['category'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  incident['date'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incident['note'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Logged by ${incident['author']}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
