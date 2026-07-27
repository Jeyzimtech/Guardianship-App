import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const borderColor = Color(0xFFD8D8D8);

  String _selectedClass = 'Grade 4 Gold (Homeroom)';

  // Class Roster & Attendance Marking State
  final List<Map<String, dynamic>> _roster = [
    {'id': 'STU001', 'name': 'Alice Chewe', 'status': 'Present', 'fees': 'Paid', 'merits': 12},
    {'id': 'STU002', 'name': 'Kudzai Moyo', 'status': 'Present', 'fees': 'Paid', 'merits': 8},
    {'id': 'STU003', 'name': 'Tafadzwa Ndlovu', 'status': 'Absent', 'fees': 'USD \$120.00 Pending', 'merits': 5},
    {'id': 'STU004', 'name': 'Tinashe Sibanda', 'status': 'Present', 'fees': 'Paid', 'merits': 15},
    {'id': 'STU005', 'name': 'Chipo Mutasa', 'status': 'Late', 'fees': 'Paid', 'merits': 10},
  ];

  // Activities Roster State
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Junior Chess Club', 'time': '01:30 PM', 'assigned_students': 18, 'attendance_done': true},
    {'name': 'Grade 4 Athletics', 'time': '03:00 PM', 'assigned_students': 24, 'attendance_done': false},
  ];

  void _toggleAttendance(int index, String status) {
    setState(() {
      _roster[index]['status'] = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance updated for ${_roster[index]['name']} -> $status'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _awardMerit(int index) {
    setState(() {
      _roster[index]['merits'] = (_roster[index]['merits'] as int) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Merit point awarded to ${_roster[index]['name']}! Total: ${_roster[index]['merits']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherName = authProvider.user?['name'] ?? 'Teacher Grace';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Mobile Scope Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TEACHER MOBILE CONSOLE • Scoped strictly for class attendance, learning journal, and conduct tracking.',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D), letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 1. Teacher Scoped Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: const Border(
                top: BorderSide(color: primaryBlue, width: 4.0),
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, color: primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TEACHER WORKSPACE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CLASS SCOPED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: secondaryBlue,
                      child: Text('TG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Assigned Homeroom: Grade 4 Gold • Mathematics & Science Teacher',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Class Roster & Daily Attendance Marking
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fact_check_rounded, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Class Roster & Daily Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedClass,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue),
                      items: const [
                        DropdownMenuItem(value: 'Grade 4 Gold (Homeroom)', child: Text('Grade 4 Gold')),
                        DropdownMenuItem(value: 'Grade 5 Blue (Maths)', child: Text('Grade 5 Blue')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mark daily present/absent status for students in your assigned homeroom/subject class.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),

                // Roster Table List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roster.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final student = _roster[index];
                    final status = student['status'];

                    Color statusBg = const Color(0xFFDCFCE7);
                    Color statusText = const Color(0xFF16A34A);
                    if (status == 'Absent') {
                      statusBg = const Color(0xFFFEE2E2);
                      statusText = const Color(0xFFDC2626);
                    } else if (status == 'Late') {
                      statusBg = const Color(0xFFFEF3C7);
                      statusText = const Color(0xFFD97706);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      student['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        '⭐ ${student['merits']} Merits',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${student['id']} • Fee Status: ${student['fees']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: student['fees'].toString().contains('Pending') ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Attendance Action Buttons
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.stars_rounded, color: Colors.amber[700], size: 22),
                                tooltip: 'Award Merit Point',
                                onPressed: () => _awardMerit(index),
                              ),
                              GestureDetector(
                                onTap: () => _toggleAttendance(index, status == 'Present' ? 'Absent' : 'Present'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    status,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusText),
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Extracurricular Activity Rosters & Attendance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_soccer_rounded, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 8),
                    Text('Activities & Extracurricular Rosters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF059669))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mark activity attendance for students opting into grade-level clubs & sports today.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final act = _activities[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(act['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                                const SizedBox(height: 2),
                                Text('${act['time']} • ${act['assigned_students']} Students Enrolled', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                act['attendance_done'] = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Activity attendance marked for ${act['name']}')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: act['attendance_done'] ? const Color(0xFF059669) : primaryBlue,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: Text(act['attendance_done'] ? 'Completed' : 'Mark Attendance'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Report Cards, Merits & Parent Communication Module
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.upload_file_rounded, color: Color(0xFF7E22CE), size: 20),
                    SizedBox(width: 8),
                    Text('Report Cards, Merits & Parent Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7E22CE))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upload term report cards, merit certificates, and send notices directly to parents in your class.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report Card Upload portal ready for Grade 4 Gold.')),
                          );
                        },
                        icon: const Icon(Icons.file_upload_rounded, size: 16),
                        label: const Text('Upload Report Cards'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7E22CE),
                          side: const BorderSide(color: Color(0xFF7E22CE)),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Class Notice published to Grade 4 Gold parents!')),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Post Class Notice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E22CE),
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
  }
}
