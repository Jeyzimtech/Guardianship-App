import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import 'add_roster_student_dialog.dart';
import '../dashboard/announcements_view.dart';

/// Classroom workspace with roster, attendance, marks and notices.
class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  // Active Tab Index: 0: Roster, 1: Roll Call, 2: Gradebook, 3: Notices
  int _activeTabIndex = 0;

  // Roster Filters & Search
  String _rosterSearchQuery = '';
  String _rosterStatusFilter = 'All'; // All, Present, Absent, Late

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noticeSubjectController =
      TextEditingController();
  final TextEditingController _noticeBodyController = TextEditingController();

  // Class Roster State with realistic student & guardian records
  final List<Map<String, dynamic>> _roster = [
    {
      'id': 'STU-001',
      'roll': '01',
      'name': 'Alice Chewe',
      'gender': 'Female',
      'guardian': 'John Chewe',
      'guardian_phone': '+263 77 241 8932',
      'status': 'Present',
      'merits': 12,
      'math_mark': 88,
      'science_mark': 92,
      'english_mark': 85,
    },
    {
      'id': 'STU-002',
      'roll': '02',
      'name': 'Bob Chewe',
      'gender': 'Male',
      'guardian': 'John Chewe',
      'guardian_phone': '+263 77 241 8932',
      'status': 'Present',
      'merits': 14,
      'math_mark': 82,
      'science_mark': 89,
      'english_mark': 78,
    },
    {
      'id': 'STU-003',
      'roll': '03',
      'name': 'Kudzai Moyo',
      'gender': 'Male',
      'guardian': 'Tariro Moyo',
      'guardian_phone': '+263 71 832 9401',
      'status': 'Present',
      'merits': 8,
      'math_mark': 74,
      'science_mark': 81,
      'english_mark': 76,
    },
    {
      'id': 'STU-004',
      'roll': '04',
      'name': 'Tafadzwa Ndlovu',
      'gender': 'Male',
      'guardian': 'Sipho Ndlovu',
      'guardian_phone': '+263 78 510 3274',
      'status': 'Absent',
      'merits': 5,
      'math_mark': 68,
      'science_mark': 70,
      'english_mark': 65,
    },
    {
      'id': 'STU-005',
      'roll': '05',
      'name': 'Tinashe Sibanda',
      'gender': 'Male',
      'guardian': 'Grace Sibanda',
      'guardian_phone': '+263 77 694 1128',
      'status': 'Present',
      'merits': 15,
      'math_mark': 95,
      'science_mark': 98,
      'english_mark': 91,
    },
    {
      'id': 'STU-006',
      'roll': '06',
      'name': 'Chipo Mutasa',
      'gender': 'Female',
      'guardian': 'Blessed Mutasa',
      'guardian_phone': '+263 77 385 4910',
      'status': 'Late',
      'merits': 10,
      'math_mark': 83,
      'science_mark': 86,
      'english_mark': 88,
    },
  ];

  // Class Announcements State
  final List<Map<String, dynamic>> _notices = [
    {
      'subject': 'Grade 4 Science Project Submissions',
      'body':
          'Please ensure all model solar system projects are brought to school by Friday morning for the term exhibition.',
      'date': 'Today, 08:30 AM',
    },
    {
      'subject': 'Upcoming Parent-Teacher Consultations',
      'body':
          'Term 2 progress review meetings will take place next Wednesday. Time slot reservations are now active on the portal.',
      'date': 'Yesterday, 02:15 PM',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _noticeSubjectController.dispose();
    _noticeBodyController.dispose();
    super.dispose();
  }

  // Filtered roster by search query and attendance status
  List<Map<String, dynamic>> get _filteredRoster {
    return _roster.where((student) {
      final q = _rosterSearchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          student['name'].toString().toLowerCase().contains(q) ||
          student['id'].toString().toLowerCase().contains(q) ||
          student['guardian'].toString().toLowerCase().contains(q);

      bool matchesStatus = true;
      if (_rosterStatusFilter != 'All') {
        matchesStatus = student['status'] == _rosterStatusFilter;
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
        content: Text('${_roster[index]['name']} marked $status'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _awardMerit(int index) {
    setState(() {
      _roster[index]['merits'] = (_roster[index]['merits'] as int) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Awarded 1 merit to ${_roster[index]['name']}! Total: ${_roster[index]['merits']}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
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
        _roster.add({
          'id': result['id'] ?? 'STU-00${_roster.length + 1}',
          'roll': result['roll'] ?? '${_roster.length + 1}'.padLeft(2, '0'),
          'name': result['name'] ?? 'New Student',
          'gender': result['gender'] ?? 'Female',
          'guardian': result['guardian'] ?? 'Parent',
          'guardian_phone': result['guardian_phone'] ?? '+263 77 000 0000',
          'status': 'Present',
          'merits': 0,
          'math_mark': 75,
          'science_mark': 75,
          'english_mark': 75,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['name']} added to Class Roster!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
          content: Text('Please enter notice title and message details.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _notices.insert(0, {
        'subject': subject,
        'body': body,
        'date': 'Just now',
      });
      _noticeSubjectController.clear();
      _noticeBodyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class announcement posted to families!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactBottomSheet(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: AppColors.softBlue),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.contact_phone_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Guardian of ${student['name']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student['guardian']} • ${student['guardian_phone']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),
            _buildContactActionTile(
              icon: Icons.phone_outlined,
              title: 'Voice Call',
              subtitle: 'Dial guardian phone directly',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Calling ${student['guardian']} (${student['guardian_phone']})...',
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildContactActionTile(
              icon: Icons.sms_outlined,
              title: 'Send SMS Alert',
              subtitle: 'Send direct cellular text alert',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening SMS to ${student['guardian']}...'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildContactActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'In-App Message',
              subtitle: 'Start direct thread in Guardianship App',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening chat with ${student['guardian']}...',
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMarksDialog(int index) {
    final student = _roster[index];
    final mathController = TextEditingController(
      text: student['math_mark']?.toString() ?? '75',
    );
    final scienceController = TextEditingController(
      text: student['science_mark']?.toString() ?? '80',
    );
    final englishController = TextEditingController(
      text: student['english_mark']?.toString() ?? '78',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Assessment Marks: ${student['name']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primaryDark,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: mathController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  'Mathematics (%)',
                  Icons.calculate_outlined,
                ),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 0 || val > 100) {
                    return 'Enter mark between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: scienceController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  'Science (%)',
                  Icons.science_outlined,
                ),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 0 || val > 100) {
                    return 'Enter mark between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: englishController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  'English (%)',
                  Icons.menu_book_outlined,
                ),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 0 || val > 100) {
                    return 'Enter mark between 0 and 100';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                _roster[index]['math_mark'] = int.parse(
                  mathController.text.trim(),
                );
                _roster[index]['science_mark'] = int.parse(
                  scienceController.text.trim(),
                );
                _roster[index]['english_mark'] = int.parse(
                  englishController.text.trim(),
                );
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Updated marks for ${student['name']}'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Marks'),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  String _formattedTodayDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _getTeacherInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'T';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final teacher =
        context.watch<AuthProvider>().user?['name'] ?? 'Teacher Grace';
    final present = _roster.where((s) => s['status'] == 'Present').length;
    final absent = _roster.where((s) => s['status'] == 'Absent').length;
    final late = _roster.where((s) => s['status'] == 'Late').length;
    const tabs = ['Students', 'Roll call', 'Gradebook', 'Notices'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Classroom'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            PageHeading(
              title: 'Your classroom',
              subtitle: '${_formattedTodayDate()} · Grade 4 Gold',
              symbol: AppSymbol.school,
            ),
            PageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.softBlue,
                        foregroundColor: AppColors.primary,
                        child: Text(_getTeacherInitials(teacher)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_roster.length} students · Homeroom',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      PageBadge(
                        '$present present',
                        color: const Color(0xFF047857),
                      ),
                      PageBadge(
                        '$absent absent',
                        color: const Color(0xFFB91C1C),
                      ),
                      PageBadge('$late late', color: const Color(0xFF92400E)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PageFilters(
              labels: tabs,
              selected: tabs[_activeTabIndex],
              onSelected: (tab) =>
                  setState(() => _activeTabIndex = tabs.indexOf(tab)),
            ),
            const SizedBox(height: 20),
            if (_activeTabIndex == 0) ..._studentList(),
            if (_activeTabIndex == 1) ..._rollCall(),
            if (_activeTabIndex == 2) ..._gradebook(),
            if (_activeTabIndex == 3) ..._classNotices(),
          ],
        ),
      ),
    );
  }

  Color _attendanceColor(String status) => switch (status) {
    'Present' => const Color(0xFF047857),
    'Absent' => const Color(0xFFB91C1C),
    _ => const Color(0xFF92400E),
  };

  Widget _studentHeading(Map<String, dynamic> student) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          student['roll'],
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student['name'],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${student['id']} · ${student['gender']}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ],
  );

  List<Widget> _studentList() => [
    Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${_filteredRoster.length} students',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        TextButton.icon(
          onPressed: _openAddStudentDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add student'),
        ),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _rosterSearchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search name, ID or guardian',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _rosterSearchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _rosterSearchQuery = '');
                },
              ),
      ),
    ),
    const SizedBox(height: 12),
    PageFilters(
      labels: const ['All', 'Present', 'Absent', 'Late'],
      selected: _rosterStatusFilter,
      onSelected: (value) => setState(() => _rosterStatusFilter = value),
    ),
    const SizedBox(height: 16),
    if (_filteredRoster.isEmpty)
      const PageEmpty(
        title: 'No students found',
        message: 'Try a different name or attendance filter.',
      ),
    for (final student in _filteredRoster)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _studentHeading(student),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PageBadge(
                    student['status'],
                    color: _attendanceColor(student['status']),
                  ),
                  PageBadge('${student['merits']} merits'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Guardian · ${student['guardian']}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _awardMerit(_roster.indexOf(student)),
                    child: const Text('Award merit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showContactBottomSheet(student),
                    icon: const AppIcon(AppSymbol.message, size: 18),
                    label: const Text('Contact'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _rollCall() => [
    const Text(
      'Daily attendance',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    const Text(
      'Select a status for each student.',
      style: TextStyle(color: AppColors.textMuted),
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => setState(() {
          for (final student in _roster) {
            student['status'] = 'Present';
          }
        }),
        child: const Text('Mark all present'),
      ),
    ),
    for (final student in _roster)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _studentHeading(student),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ['Present', 'Absent', 'Late']
                    .map(
                      (status) => ChoiceChip(
                        label: Text(status),
                        selected: student['status'] == status,
                        showCheckmark: false,
                        selectedColor: _attendanceColor(
                          status,
                        ).withValues(alpha: .12),
                        labelStyle: TextStyle(
                          color: _attendanceColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) =>
                            _toggleAttendance(_roster.indexOf(student), status),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    FilledButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved for this session.')),
      ),
      child: const Text('Save register'),
    ),
  ];

  List<Widget> _gradebook() => [
    const Text(
      'Assessment overview',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    const Text(
      'Review subject marks and update assessments.',
      style: TextStyle(color: AppColors.textMuted, height: 1.5),
    ),
    const SizedBox(height: 16),
    for (final student in _roster)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _studentHeading(student),
              const SizedBox(height: 20),
              for (final subject in {
                'Mathematics': 'math_mark',
                'Science': 'science_mark',
                'English': 'english_mark',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(subject.key)),
                          Text(
                            '${student[subject.value]}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ((student[subject.value] as int? ?? 0) / 100)
                            .clamp(0, 1),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: AppColors.softBlue,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () =>
                      _showEditMarksDialog(_roster.indexOf(student)),
                  child: const Text('Edit marks'),
                ),
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _classNotices() => [
    OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnnouncementsView()),
      ),
      icon: const Icon(Icons.campaign_outlined),
      label: const Text('School noticeboard'),
    ),
    const SizedBox(height: 16),
    PageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a class notice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep families informed about class activities.',
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noticeSubjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeBodyController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _publishNotice,
            child: const Text('Post notice'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Recent notices',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 16),
    for (final notice in _notices)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageBadge(notice['date']),
              const SizedBox(height: 12),
              Text(
                notice['subject'],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notice['body'],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _notices.remove(notice)),
                child: const Text('Remove notice'),
              ),
            ],
          ),
        ),
      ),
  ];
}
