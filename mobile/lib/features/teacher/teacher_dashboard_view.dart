import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
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

  // Class Roster State dynamically loaded from backend database
  List<Map<String, dynamic>> _roster = [];
  DateTime _attendanceDate = DateUtils.dateOnly(DateTime.now());
  bool _isSavingAttendance = false;
  bool _isLoadingRoster = false;

  // Behaviour categories configured by the school admin.
  List<Map<String, dynamic>> _categories = [];

  // Activity rosters
  List<Map<String, dynamic>> _activities = [];
  bool _isLoadingActivities = false;

  // Class chosen for a class notice; null sends to all assigned classes.
  String? _noticeClass;

  @override
  void initState() {
    super.initState();
    _loadTeacherStudents();
    _loadCategories();
    _loadActivities();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get('/behaviour-categories');
      final list = (response.data['categories'] as List? ?? []);
      if (mounted) setState(() => _categories = list.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {}
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get('/activities');
      final list = (response.data['activities'] as List? ?? []);
      if (mounted) setState(() => _activities = list.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  List<String> get _classNames => _roster
      .map((s) => '${s['grade'] ?? ''}|${s['class_name'] ?? ''}')
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> _loadTeacherStudents() async {
    setState(() => _isLoadingRoster = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final date = '${_attendanceDate.year.toString().padLeft(4, '0')}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';
      final response = await auth.apiClient.dio.get('/attendance/roster', queryParameters: {'date': date});
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final list = (response.data['roster'] as List? ?? []);
        if (mounted) {
          setState(() {
            _roster = list.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value as Map<String, dynamic>;
              final guardians = (m['guardians'] as List? ?? []);
              final guardianStr = guardians.isNotEmpty
                  ? (guardians[0]['name']?.toString() ?? 'Guardian')
                  : 'Guardian';
              return {
                'student_id': m['student_id'],
              'id': 'STU-${(m['student_id'] ?? idx + 1).toString().padLeft(3, '0')}',
                'roll': (idx + 1).toString().padLeft(2, '0'),
                'name': m['name'] ?? '',
                'class_name': m['class_name'] ?? '',
                'grade': m['grade'] ?? '',
                'guardian': guardianStr,
                'guardians': guardians,
                'status': (m['status'] ?? 'present').toString().replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()),
                'merits': 0,
              };
            }).toList();
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingRoster = false);
    }
  }

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

  Future<void> _saveAttendance() async {
    if (_roster.isEmpty || _isSavingAttendance) return;
    setState(() => _isSavingAttendance = true);
    try {
      final date = '${_attendanceDate.year.toString().padLeft(4, '0')}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';
      await context.read<AuthProvider>().apiClient.dio.post('/attendance/mark', data: {
        'date': date,
        'records': _roster.map((student) => {
          'student_id': student['student_id'],
          'status': student['status'].toString().toLowerCase(),
        }).toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance register saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance could not be saved. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSavingAttendance = false);
    }
  }

  Future<void> _changeAttendanceDate(int offset) async {
    setState(() => _attendanceDate = DateUtils.dateOnly(_attendanceDate.add(Duration(days: offset))));
    await _loadTeacherStudents();
  }

  Future<void> _logBehaviour(int index, String polarity) async {
    final student = _roster[index];
    final options = _categories
        .where((c) => c['polarity'] == polarity)
        .map((c) => c['name'].toString())
        .toList();
    final categoryController = TextEditingController(
      text: options.isEmpty ? (polarity == 'positive' ? 'Merit' : '') : '',
    );
    final noteController = TextEditingController();
    String? selected = options.isEmpty ? null : options.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(polarity == 'positive' ? 'Award merit' : 'Log conduct note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (options.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) => setDialogState(() => selected = v),
                )
              else
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Note for parents (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final category = (selected ?? categoryController.text).trim();
    final note = noteController.text.trim();
    categoryController.dispose();
    noteController.dispose();
    if (confirmed != true || !mounted) return;
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a category.')));
      return;
    }

    try {
      await context.read<AuthProvider>().apiClient.dio.post('/behaviour', data: {
        'student_id': student['student_id'],
        'polarity': polarity,
        'category': category,
        'note': note.isEmpty ? null : note,
        'incident_date': DateTime.now().toIso8601String().substring(0, 10),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Behaviour saved for ${student['name']}.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Behaviour record could not be saved.')));
    }
  }

  Future<void> _createActivity() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime date = DateUtils.dateOnly(DateTime.now());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(_isoDate(date)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(date.year - 1),
                    lastDate: DateTime(date.year + 1),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    titleController.dispose();
    descriptionController.dispose();
    if (confirmed != true || title.isEmpty || !mounted) return;

    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post('/activities', data: {
        'title': title,
        'description': description.isEmpty ? null : description,
        'activity_date': _isoDate(date),
      });
      await _loadActivities();
      final created = response.data['activity'];
      if (mounted && created != null) _openActivityRoster(Map<String, dynamic>.from(created));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity could not be created.')));
    }
  }

  Future<void> _openActivityRoster(Map<String, dynamic> activity) async {
    final dio = context.read<AuthProvider>().apiClient.dio;
    List<Map<String, dynamic>> roster;
    try {
      final response = await dio.get('/activities/${activity['id']}/roster');
      roster = (response.data['roster'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roster could not be loaded.')));
      return;
    }
    // Status per learner: null = not on roster.
    final statuses = {
      for (final s in roster) s['student_id']: s['status'] ?? (s['on_roster'] == true ? 'present' : null),
    };
    final originallyOnRoster = {for (final s in roster) if (s['on_roster'] == true) s['student_id']};
    if (!mounted) return;

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .8,
            child: Column(
              children: [
                ListTile(
                  title: Text(activity['title']?.toString() ?? 'Activity',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mark who took part'),
                  trailing: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Save'),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: roster.isEmpty
                      ? const Center(child: Text('No students in your classes.'))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final s in roster)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${s['name']} · ${s['class_name'] ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final option in const [
                                          [null, 'Not on roster'],
                                          ['present', 'Took part'],
                                          ['late', 'Late'],
                                          ['absent', 'Absent'],
                                        ])
                                          ChoiceChip(
                                            label: Text(option[1]!),
                                            selected: statuses[s['student_id']] == option[0],
                                            showCheckmark: false,
                                            onSelected: (_) =>
                                                setSheetState(() => statuses[s['student_id']] = option[0]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (save != true || !mounted) return;

    final records = [
      for (final entry in statuses.entries)
        if (entry.value != null || originallyOnRoster.contains(entry.key))
          {'student_id': entry.key, 'status': entry.value},
    ];
    if (records.isEmpty) return;
    try {
      await dio.post('/activities/${activity['id']}/roster', data: {'records': records});
      await _loadActivities();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity roster saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity roster could not be saved.')));
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _publishNotice() async {
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

    try {
      await context.read<AuthProvider>().apiClient.dio.post('/announcements', data: {
        'title': subject,
        'content': body,
        'audience_role': 'guardian',
        if (_noticeClass != null) 'class_name': _noticeClass!.split('|').last,
        if (_noticeClass != null) 'grade': _noticeClass!.split('|').first,
      });
      setState(() {
        _noticeSubjectController.clear();
        _noticeBodyController.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice sent to parents in your class.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement could not be posted.')));
    }
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

  Future<void> _resendGuardianLink(Map<String, dynamic> guardian) async {
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post('/users/${guardian['id']}/send-link');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Invitation sent.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send the invitation. Please contact your school administrator.')));
    }
  }

  Future<void> _inviteGuardian(Map<String, dynamic> student) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final form = GlobalKey<FormState>();
    bool sending = false;
    String? error;
    await showDialog<void>(context: context, barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, update) => AlertDialog(
        title: const Text('Invite guardian'),
        content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Create a parent or guardian account for ${student['name']}. Email and phone are optional. Add either contact detail to enable sign-in.'),
          const SizedBox(height: 16),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Guardian name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null),
          const SizedBox(height: 12),
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address (optional)'), validator: (v) => v != null && v.trim().isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
          const SizedBox(height: 12),
          TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number (optional)')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        ]))),
        actions: [
          TextButton(onPressed: sending ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: sending ? null : () async {
            if (!form.currentState!.validate()) return;
            update(() { sending = true; error = null; });
            try {
              final response = await context.read<AuthProvider>().apiClient.dio.post('/users', data: {
                'name': name.text.trim(), 'email': email.text.trim(), 'phone_number': phone.text.trim(),
                'role': 'guardian', 'student_ids': [student['student_id']],
              });
              if (!mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Guardian account created.')));
              await _loadTeacherStudents();
            } catch (exception) {
              if (!dialogContext.mounted) return;
              final data = exception is DioException ? exception.response?.data : null;
              update(() { sending = false; error = data is Map ? data['message']?.toString() ?? 'Could not create this account.' : 'Could not create this account. Please try again.'; });
            }
          }, child: Text(sending ? 'Sending?' : 'Send invitation')),
        ],
      )),
    );
    // Wait for the dialog transition before releasing its field controllers.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose(); email.dispose(); phone.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacher =
        context.watch<AuthProvider>().user?['name'] ?? 'Teacher';
    final present = _roster.where((s) => s['status'] == 'Present').length;
    final absent = _roster.where((s) => s['status'] == 'Absent').length;
    final late = _roster.where((s) => s['status'] == 'Late').length;
    const tabs = ['Students', 'Roll call', 'Activities', 'Notices'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Classroom'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            PageHeading(
              title: 'Your classroom',
              subtitle: '${_formattedTodayDate()} · Assigned classes',
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
                  Row(
                    children: [
                      IconButton(onPressed: () => _changeAttendanceDate(-1), icon: const Icon(Icons.chevron_left)),
                      Expanded(child: Center(child: Text('Attendance · ${_formattedTodayDate()}', style: const TextStyle(fontWeight: FontWeight.w600)))),
                      IconButton(onPressed: () => _changeAttendanceDate(1), icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
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
            if (_activeTabIndex == 2) ..._activityRosters(),
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
              '${student['id']} · ${student['class_name'] ?? ''}',
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
    if (_isLoadingRoster)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      )
    else if (_filteredRoster.isEmpty)
      const PageEmpty(
        title: 'No students found',
        message: 'No learners currently match this roster filter.',
      )
    else
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
                    onPressed: () => _logBehaviour(_roster.indexOf(student), 'positive'),
                    child: const Text('Award merit'),
                  ),
                  OutlinedButton(
                    onPressed: () => _logBehaviour(_roster.indexOf(student), 'negative'),
                    child: const Text('Conduct note'),
                  ),
                  OutlinedButton(onPressed: () => _inviteGuardian(student), child: const Text('Invite guardian')),
                  for (final guardian in (student['guardians'] as List? ?? []))
                    if (guardian['email'] != null && guardian['email'].toString().isNotEmpty)
                      TextButton(onPressed: () => _resendGuardianLink(Map<String, dynamic>.from(guardian)), child: Text('Resend link to ${guardian['name']}')),
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
    FilledButton.icon(
      onPressed: _isSavingAttendance || _roster.isEmpty ? null : _saveAttendance,
      icon: _isSavingAttendance ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
      label: Text(_isSavingAttendance ? 'Saving…' : 'Save register'),
    ),
  ];

  List<Widget> _activityRosters() => [
    Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Activity rosters',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        FilledButton.icon(
          onPressed: _createActivity,
          icon: const Icon(Icons.add),
          label: const Text('New activity'),
        ),
      ],
    ),
    const SizedBox(height: 6),
    const Text(
      'Record which of your students took part. Parents see this in the app.',
      style: TextStyle(color: AppColors.textMuted),
    ),
    const SizedBox(height: 16),
    if (_isLoadingActivities)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      )
    else if (_activities.isEmpty)
      const PageEmpty(
        title: 'No activities yet',
        message: 'Create an activity to start a roster.',
      )
    else
      for (final activity in _activities)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PageCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']?.toString() ?? '',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['activity_date']?.toString().split('T').first ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PageBadge('${activity['roster_count'] ?? 0} on roster'),
                    PageBadge(
                      '${activity['participated_count'] ?? 0} took part',
                      color: const Color(0xFF047857),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _openActivityRoster(activity),
                  child: const Text('Mark roster'),
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
            'Only parents of students in your classes receive class notices.',
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (_classNames.length > 1) ...[
            DropdownButtonFormField<String?>(
              initialValue: _noticeClass,
              decoration: const InputDecoration(labelText: 'Send to'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All my classes')),
                for (final c in _classNames) DropdownMenuItem(value: c, child: Text(c.replaceAll('|', ' ? '))),
              ],
              onChanged: (v) => setState(() => _noticeClass = v),
            ),
            const SizedBox(height: 12),
          ],
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
  ];
}
