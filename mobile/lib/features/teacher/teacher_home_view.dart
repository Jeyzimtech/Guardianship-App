import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

/// Teacher Home screen — matches the "Good Morning" Stitch MCP design
class TeacherHomeView extends StatefulWidget {
  const TeacherHomeView({super.key});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  static const primaryBlue = Color(0xFF3B5998);

  String _selectedClass = 'Grade 4A';

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
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherName = authProvider.user?['name'] ?? 'Mrs. Davis';
    final firstName = teacherName.split(' ').last;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GREETING ──
          Text(
            '${_greeting()}, $firstName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Here is your overview for today.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),

          // ── ACTIVE CLASS CARD ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE CLASS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedClass,
                        underline: const SizedBox(),
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: primaryBlue, size: 18),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Grade 4A',
                              child: Text('Grade 4A — 32 Students')),
                          DropdownMenuItem(
                              value: 'Grade 5B',
                              child: Text('Grade 5B — 28 Students')),
                          DropdownMenuItem(
                              value: 'Grade 6C',
                              child: Text('Grade 6C — 30 Students')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedClass = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── QUICK ACTION BUTTONS ──
          _buildActionButton(
            label: 'Mark Attendance',
            subtitle: 'Record today\'s class attendance',
            filled: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Opening attendance sheet...'),
                  backgroundColor: primaryBlue),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Publish Learning Post',
            subtitle: 'Add an entry to the class journal',
            filled: false,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening learning journal post...')),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Create Homework',
            subtitle: 'Assign homework tasks to students',
            filled: false,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening homework creator...')),
            ),
          ),
          const SizedBox(height: 24),

          // ── TODAY'S SCHEDULE ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _todayLabel(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedule.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (ctx, i) {
                final item = _schedule[i];
                final isDone = item['done'] as bool;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Time
                      SizedBox(
                        width: 44,
                        child: Text(
                          item['time'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? const Color(0xFF9CA3AF)
                                : primaryBlue,
                          ),
                        ),
                      ),
                      // Blue vertical line indicator
                      Container(
                        width: 3,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFD1D5DB)
                              : primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Subject
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['subject'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDone
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF1F2937),
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            Text(
                              item['duration'],
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      // Status
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => setState(() => item['done'] = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: primaryBlue.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Mark Done',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── QUICK STATS ROW ──
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                    '32', 'Students', const Color(0xFF3B5998), const Color(0xFFEFF6FF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickStat(
                    '94%', 'Attendance', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickStat(
                    '3', 'Pending Tasks', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: filled ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? primaryBlue : const Color(0xFFE5E7EB),
            width: filled ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: filled ? 0.08 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: filled ? Colors.white : primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: filled
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
