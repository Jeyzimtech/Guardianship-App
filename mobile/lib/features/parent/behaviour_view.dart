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
    final totalPoints = (positiveCount * 5) + 27; // mock house points tally

    final badges = [
      {'label': 'Star Reader', 'color': const Color(0xFF3B5998), 'bg': const Color(0xFFEFF6FF)},
      {'label': 'Helpful Peer', 'color': const Color(0xFF059669), 'bg': const Color(0xFFDCFCE7)},
      {'label': 'Math Champion', 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF5F3FF)},
      {'label': 'Punctual', 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)},
      {'label': 'Clean Desk', 'color': const Color(0xFF0891B2), 'bg': const Color(0xFFE0F2FE)},
      {'label': 'Team Player', 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Behaviour & Merits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${child?['name'] ?? 'Student'} — Conduct Record',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HOUSE POINTS SUMMARY CARD ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'HOUSE POINTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalPoints',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Total Points Earned This Term',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniStat('$positiveCount', 'Merits', const Color(0xFF86EFAC)),
                      const SizedBox(width: 32),
                      _buildMiniStat('$negativeCount', 'Conduct Alerts', const Color(0xFFFCA5A5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── BADGES EARNED SECTION ──
            const Text(
              'Badges Earned',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              itemCount: badges.length,
              itemBuilder: (context, i) {
                final badge = badges[i];
                return Container(
                  decoration: BoxDecoration(
                    color: badge['bg'] as Color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (badge['color'] as Color).withValues(alpha: 0.25),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    badge['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badge['color'] as Color,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // ── CONDUCT LOG SECTION ──
            const Text(
              'Conduct Record',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isPositive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        width: 4,
                      ),
                      top: const BorderSide(color: Color(0xFFE2E8F0)),
                      right: const BorderSide(color: Color(0xFFE2E8F0)),
                      bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                incident['category'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1F2937)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPositive ? 'MERIT' : 'NOTE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          incident['note'] ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                              height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Logged by ${incident['author']}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              incident['date'] ?? '',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Text(
                'Conduct records are submitted by class teachers and visible only to the linked guardian.',
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}
