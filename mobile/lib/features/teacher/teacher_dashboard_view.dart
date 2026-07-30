import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import 'add_roster_student_dialog.dart';

class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  // Admin Web Design Color Tokens
  static const primaryBlue = Color(0xFF3B5998);
  static const primaryHover = Color(0xFF2D4373);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const bgLight = Color(0xFFF9FAFB);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFD8D8D8);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);

  // Admin Web Badge Colors
  static const successBg = Color(0xFFDCFCE7);
  static const successText = Color(0xFF16A34A);
  static const dangerBg = Color(0xFFFEE2E2);
  static const dangerText = Color(0xFFDC2626);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningText = Color(0xFFD97706);
  static const infoBg = Color(0xFFE0F2FE);
  static const infoText = Color(0xFF0284C7);

  String _selectedClass = 'Grade 4 Gold (Homeroom)';
  int _activeTabIndex = 0; // 0: Class Roster, 1: Daily Attendance, 2: Gradebook, 3: Activities, 4: Class Notices

  // Roster Filters & Search
  String _rosterSearchQuery = '';
  String _rosterStatusFilter = 'All'; // All, Present, Absent, Late, Pending Fees

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noticeSubjectController = TextEditingController();
  final TextEditingController _noticeBodyController = TextEditingController();

  // Class Roster Initial State
  final List<Map<String, dynamic>> _roster = [
    {
      'id': 'STU001',
      'roll': '01',
      'name': 'Alice Chewe',
      'gender': 'Female',
      'guardian': 'John Chewe',
      'guardian_phone': '+263773333333',
      'status': 'Present',
      'fees': 'Paid',
      'merits': 12,
      'math_mark': 88,
      'science_mark': 92,
    },
    {
      'id': 'STU002',
      'roll': '02',
      'name': 'Kudzai Moyo',
      'gender': 'Male',
      'guardian': 'Tariro Moyo',
      'guardian_phone': '+263778888888',
      'status': 'Present',
      'fees': 'Paid',
      'merits': 8,
      'math_mark': 74,
      'science_mark': 81,
    },
    {
      'id': 'STU003',
      'roll': '03',
      'name': 'Tafadzwa Ndlovu',
      'gender': 'Male',
      'guardian': 'Sipho Ndlovu',
      'guardian_phone': '+263779999999',
      'status': 'Absent',
      'fees': 'USD \$120.00 Pending',
      'merits': 5,
      'math_mark': 62,
      'science_mark': 70,
    },
    {
      'id': 'STU004',
      'roll': '04',
      'name': 'Tinashe Sibanda',
      'gender': 'Male',
      'guardian': 'Grace Sibanda',
      'guardian_phone': '+263772222222',
      'status': 'Present',
      'fees': 'Paid',
      'merits': 15,
      'math_mark': 95,
      'science_mark': 98,
    },
    {
      'id': 'STU005',
      'roll': '05',
      'name': 'Chipo Mutasa',
      'gender': 'Female',
      'guardian': 'Blessed Mutasa',
      'guardian_phone': '+263775555555',
      'status': 'Late',
      'fees': 'Paid',
      'merits': 10,
      'math_mark': 83,
      'science_mark': 86,
    },
  ];

  // Activities Roster State
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Junior Chess Club', 'time': '01:30 PM', 'assigned_students': 18, 'location': 'Library Hall', 'attendance_done': true},
    {'name': 'Grade 4 Athletics Team', 'time': '03:00 PM', 'assigned_students': 24, 'location': 'Sports Field', 'attendance_done': false},
    {'name': 'Music & Drama Ensemble', 'time': '04:00 PM', 'assigned_students': 12, 'location': 'Auditorium', 'attendance_done': false},
  ];

  // Class Notices State
  final List<Map<String, dynamic>> _notices = [
    {
      'subject': 'Grade 4 Gold Science Project Submission Date',
      'body': 'Please ensure model solar system projects are brought to school by Friday morning.',
      'date': 'Today, 08:30 AM',
      'reads': '28 of 32 Parents Read',
    },
    {
      'subject': 'Upcoming Parent-Teacher Consultations',
      'body': 'Slot bookings for Term 2 progress meetings will open this Thursday via the portal.',
      'date': 'Yesterday, 02:15 PM',
      'reads': '32 of 32 Parents Read',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _noticeSubjectController.dispose();
    _noticeBodyController.dispose();
    super.dispose();
  }

  // Filtered roster according to search and status
  List<Map<String, dynamic>> get _filteredRoster {
    return _roster.where((student) {
      final q = _rosterSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          student['name'].toString().toLowerCase().contains(q) ||
          student['id'].toString().toLowerCase().contains(q) ||
          student['guardian'].toString().toLowerCase().contains(q);

      bool matchesStatus = true;
      if (_rosterStatusFilter == 'Present') {
        matchesStatus = student['status'] == 'Present';
      } else if (_rosterStatusFilter == 'Absent') {
        matchesStatus = student['status'] == 'Absent';
      } else if (_rosterStatusFilter == 'Late') {
        matchesStatus = student['status'] == 'Late';
      } else if (_rosterStatusFilter == 'Pending Fees') {
        matchesStatus = student['fees'].toString().contains('Pending');
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _toggleAttendance(int index, String status) {
    setState(() {
      _roster[index]['status'] = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance updated: ${_roster[index]['name']} -> $status'),
        duration: const Duration(seconds: 1),
        backgroundColor: primaryBlue,
      ),
    );
  }

  void _awardMerit(int index) {
    setState(() {
      _roster[index]['merits'] = (_roster[index]['merits'] as int) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Merit point awarded to ${_roster[index]['name']}! Total: ${_roster[index]['merits']}'),
        duration: const Duration(seconds: 1),
        backgroundColor: primaryBlue,
      ),
    );
  }

  Future<void> _openAddStudentDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddRosterStudentDialog(),
    );

    if (result != null) {
      setState(() {
        _roster.add(result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['name']} added to Class Roster successfully!'),
            backgroundColor: successText,
          ),
        );
      }
    }
  }

  void _publishNotice() {
    final subject = _noticeSubjectController.text.trim();
    final body = _noticeBodyController.text.trim();

    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both announcement subject and message body.'),
          backgroundColor: dangerText,
        ),
      );
      return;
    }

    setState(() {
      _notices.insert(0, {
        'subject': subject,
        'body': body,
        'date': 'Just now',
        'reads': '0 of 32 Parents Read',
      });
      _noticeSubjectController.clear();
      _noticeBodyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class Announcement posted to parents successfully!'),
        backgroundColor: primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherName = authProvider.user?['name'] ?? 'Teacher Grace';

    final presentCount = _roster.where((s) => s['status'] == 'Present').length;
    final totalCount = _roster.length;
    final attendancePct = totalCount > 0 ? ((presentCount / totalCount) * 100).round() : 0;
    final totalMerits = _roster.fold<int>(0, (sum, item) => sum + (item['merits'] as int));

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Teacher Profile Header — CLASS SCOPED badge on its own line
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: secondaryBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'TG',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Homeroom Class Teacher • Grade 4 Gold',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: infoBg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'CLASS SCOPED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: infoText, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      underline: const SizedBox(),
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 16),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
                      items: const [
                        DropdownMenuItem(value: 'Grade 4 Gold (Homeroom)', child: Text('Gr 4 Gold')),
                        DropdownMenuItem(value: 'Grade 5 Blue (Maths)', child: Text('Gr 5 Blue')),
                        DropdownMenuItem(value: 'Grade 6 Red (Science)', child: Text('Gr 6 Red')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Summary KPI Cards — 2×2 grid to prevent value truncation
            Row(
              children: [
                Expanded(
                  child: _buildWebKpiCard('CLASS ROSTER', '$totalCount Students', Icons.school_outlined, primaryBlue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWebKpiCard('ATTENDANCE', '$attendancePct% Today', Icons.fact_check_outlined, successText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildWebKpiCard('GRADES PENDING', '2 Tasks Due', Icons.assignment_outlined, warningText),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWebKpiCard('TOTAL MERITS', '$totalMerits Stars', Icons.star_outline_rounded, secondaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Admin Web Style Navigation Tabs Toolbar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, 'Class Roster', Icons.people_alt_outlined),
                    _buildTabButton(1, 'Daily Attendance', Icons.fact_check_outlined),
                    _buildTabButton(2, 'Gradebook & Marks', Icons.assignment_outlined),
                    _buildTabButton(3, 'Clubs & Activities', Icons.sports_soccer_outlined),
                    _buildTabButton(4, 'Class Notices', Icons.campaign_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Tab Body Content
            IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildClassRosterTab(),
                _buildDailyAttendanceTab(),
                _buildGradebookTab(),
                _buildActivitiesTab(),
                _buildClassNoticesTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Admin Web KPI Card Helper
  Widget _buildWebKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ],
      ),
    );
  }

  // Admin Web Toolbar Tab Button Helper
  Widget _buildTabButton(int index, String title, IconData icon) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryBlue : Colors.transparent,
              width: 3.0,
            ),
          ),
          color: isActive ? primaryBlue.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? primaryBlue : textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? primaryBlue : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: BASIC CLASS ROSTER (NO AI ICONS)
  // ==========================================
  Widget _buildClassRosterTab() {
    final filtered = _filteredRoster;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header / Title Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, color: primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Class Roster & Student Register (${filtered.length} Enrolled)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage homeroom students, attendance status, fee indicators, and parent contacts.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                // Button Structure Action Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting Class Roster CSV/PDF report...')),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('EXPORT ROSTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openAddStudentDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('ADD STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) return primaryHover;
                          return primaryBlue;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Toolbar (.table-toolbar matching Admin Web)
          Container(
            padding: const EdgeInsets.all(12),
            color: bgLight,
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Bar Input (.search-input matching Admin Web)
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search by student name, ID, or guardian...',
                            hintStyle: const TextStyle(fontSize: 12, color: textSecondary),
                            prefixIcon: const Icon(Icons.search, size: 18, color: textSecondary),
                            suffixIcon: _rosterSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _rosterSearchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: surfaceWhite,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _rosterSearchQuery = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Buttons Structure (.filter-btn matching Admin Web)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Filter:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('All', _roster.length),
                      _buildFilterChip('Present', _roster.where((s) => s['status'] == 'Present').length),
                      _buildFilterChip('Absent', _roster.where((s) => s['status'] == 'Absent').length),
                      _buildFilterChip('Late', _roster.where((s) => s['status'] == 'Late').length),
                      _buildFilterChip('Pending Fees', _roster.where((s) => s['fees'].toString().contains('Pending')).length),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Table Rows / Student Roster List (.data-table matching Admin Web)
          filtered.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.search_off_outlined, size: 40, color: textSecondary),
                      SizedBox(height: 8),
                      Text('No matching students found in class roster', style: TextStyle(color: textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final originalIndex = _roster.indexWhere((s) => s['id'] == student['id']);
                    final status = student['status'];
                    final fees = student['fees'].toString();

                    Color statusBg = successBg;
                    Color statusText = successText;
                    if (status == 'Absent') {
                      statusBg = dangerBg;
                      statusText = dangerText;
                    } else if (status == 'Late') {
                      statusBg = warningBg;
                      statusText = warningText;
                    }

                    Color feeBg = successBg;
                    Color feeText = successText;
                    if (fees.contains('Pending')) {
                      feeBg = dangerBg;
                      feeText = dangerText;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Roll & ID Badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: bgLight,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: borderColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  student['roll'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & Guardian Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          student['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${student['gender']})',
                                          style: const TextStyle(fontSize: 11, color: textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: bgLight,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Text(
                                            '⭐ ${student['merits']} Merits',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'ID: ${student['id']} • Guardian: ${student['guardian']} (${student['guardian_phone']})',
                                      style: const TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),

                              // Attendance & Fee Status Badges (.role-badge matching Admin Web)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: feeBg, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      fees,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: feeText),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusText),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Attendance Button Structure & Action Buttons Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Structured Attendance Switcher (P / A / L)
                              Row(
                                children: [
                                  const Text(
                                    'Attendance:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAttendanceButton(originalIndex, 'Present', 'P', successBg, successText, status == 'Present'),
                                  const SizedBox(width: 4),
                                  _buildAttendanceButton(originalIndex, 'Absent', 'A', dangerBg, dangerText, status == 'Absent'),
                                  const SizedBox(width: 4),
                                  _buildAttendanceButton(originalIndex, 'Late', 'L', warningBg, warningText, status == 'Late'),
                                ],
                              ),

                              // Extra Action Buttons
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _awardMerit(originalIndex),
                                    icon: const Icon(Icons.star_outline_rounded, size: 14, color: warningText),
                                    label: const Text('+1 MERIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: borderColor),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Calling parent ${student['guardian']} (${student['guardian_phone']})...')),
                                      );
                                    },
                                    icon: const Icon(Icons.phone_outlined, size: 14, color: primaryBlue),
                                    label: const Text('CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: borderColor),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _rosterStatusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: () => setState(() => _rosterStatusFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : surfaceWhite,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isSelected ? primaryBlue : borderColor),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(int index, String fullStatus, String code, Color bg, Color text, bool isCurrent) {
    return GestureDetector(
      onTap: () => _toggleAttendance(index, fullStatus),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isCurrent ? text : surfaceWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: text),
        ),
        alignment: Alignment.center,
        child: Text(
          code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isCurrent ? Colors.white : text,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: DAILY ATTENDANCE REGISTER
  // ==========================================
  Widget _buildDailyAttendanceTab() {
    final presentCount = _roster.where((s) => s['status'] == 'Present').length;
    final absentCount = _roster.where((s) => s['status'] == 'Absent').length;
    final lateCount = _roster.where((s) => s['status'] == 'Late').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Roll Call Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
                  SizedBox(height: 2),
                  Text('Quick daily present / absent marking session for homeroom.', style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (var s in _roster) {
                      s['status'] = 'Present';
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All class students marked Present!'), backgroundColor: successText),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('MARK ALL PRESENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendance Summary Bar
          Row(
            children: [
              _buildSummaryPill('Present Today', '$presentCount Students', successBg, successText),
              const SizedBox(width: 8),
              _buildSummaryPill('Absent Today', '$absentCount Students', dangerBg, dangerText),
              const SizedBox(width: 8),
              _buildSummaryPill('Late Arrivals', '$lateCount Students', warningBg, warningText),
            ],
          ),
          const Divider(height: 24, color: borderColor),

          // Roll call checklist
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _roster.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: bgLight),
            itemBuilder: (context, index) {
              final student = _roster[index];
              final status = student['status'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${student['roll']}.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          student['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildAttendanceButton(index, 'Present', 'P', successBg, successText, status == 'Present'),
                        const SizedBox(width: 6),
                        _buildAttendanceButton(index, 'Absent', 'A', dangerBg, dangerText, status == 'Absent'),
                        const SizedBox(width: 6),
                        _buildAttendanceButton(index, 'Late', 'L', warningBg, warningText, status == 'Late'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance Register saved & submitted to Admin Server!'), backgroundColor: primaryBlue),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('SAVE ATTENDANCE REGISTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String title, String countStr, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 2),
            Text(countStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: GRADEBOOK & MARKS ENTRY
  // ==========================================
  Widget _buildGradebookTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Academic Gradebook & Assessment Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Record student test marks, term grades, and subject evaluation summaries.', style: TextStyle(fontSize: 12, color: textSecondary)),
          const Divider(height: 24, color: borderColor),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _roster.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final student = _roster[index];
              final math = student['math_mark'] as int;
              final science = student['science_mark'] as int;
              final avg = ((math + science) / 2).round();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Math: $math% • Science: $science%', style: const TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: avg >= 80 ? successBg : (avg >= 60 ? warningBg : dangerBg),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Avg: $avg%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: avg >= 80 ? successText : (avg >= 60 ? warningText : dangerText),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gradebook entry opened for ${student['name']}')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                          ),
                          child: const Text('EDIT MARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue)),
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
    );
  }

  // ==========================================
  // TAB 4: EXTRACURRICULAR CLUBS & ACTIVITIES
  // ==========================================
  Widget _buildActivitiesTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_soccer_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Clubs & Extracurricular Activity Rosters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Track student participation in sports teams and club activities today.', style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 14),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final act = _activities[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(act['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 3),
                        Text('${act['time']} • ${act['location']} • ${act['assigned_students']} Students', style: const TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => act['attendance_done'] = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Activity attendance saved for ${act['name']}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: act['attendance_done'] ? successText : primaryBlue,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                      child: Text(
                        act['attendance_done'] ? 'COMPLETED' : 'MARK ROLL',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: CLASS NOTICES & ANNOUNCEMENTS
  // ==========================================
  Widget _buildClassNoticesTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Class Announcements & Parent Notices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Publish official circulars and notices directly to parents in your assigned class.', style: TextStyle(fontSize: 12, color: textSecondary)),
          const Divider(height: 24, color: borderColor),

          // Post Announcement Form
          TextField(
            controller: _noticeSubjectController,
            decoration: const InputDecoration(
              labelText: 'Notice Subject / Title *',
              hintText: 'e.g. Field Trip Permission Slip Reminder',
              filled: true,
              fillColor: surfaceWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: primaryBlue)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeBodyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notice Message Details *',
              hintText: 'Enter announcement body content for parents...',
              filled: true,
              fillColor: surfaceWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: primaryBlue)),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _publishNotice,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('POST CLASS NOTICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
              ),
            ),
          ),
          const Divider(height: 28, color: borderColor),

          // Announcement Feed History
          const Text('Published Class Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notices.length,
            itemBuilder: (context, index) {
              final item = _notices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(item['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue)),
                        ),
                        Text(item['date'], style: const TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item['body'], style: const TextStyle(fontSize: 12, color: textPrimary)),
                    const SizedBox(height: 6),
                    Text(item['reads'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: successText)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
