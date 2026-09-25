import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import 'create_teacher_dialog.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  bool _demo = false;
  String _filter = 'All';

  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _classes = [];

  // Mock fallbacks for offline/demo mode
  final List<Map<String, dynamic>> _mockTeachers = [
    {
      'id': 1,
      'user_id': 2,
      'school_id': 2,
      'user': {
        'name': 'Teacher Grace',
        'email': 'grace@hillside.ac.zw',
        'phone_number': '+263772222222',
      },
      'school': {'name': 'Hillside Primary School'},
      'subject_specialties': ['Mathematics', 'English', 'Shona'],
      'assigned_classes': [
        {
          'id': 2,
          'grade': 'Grade 1',
          'class_name': 'Green',
          'pivot': {'subject_name': 'Homeroom'},
        },
        {
          'id': 3,
          'grade': 'Grade 4',
          'class_name': 'Gold',
          'pivot': {'subject_name': 'Mathematics'},
        },
      ],
    },
    {
      'id': 2,
      'user_id': 4,
      'school_id': 3,
      'user': {
        'name': 'Teacher Farai',
        'email': 'farai@hillside.ac.zw',
        'phone_number': '+263774444444',
      },
      'school': {'name': 'Hillside Secondary School'},
      'subject_specialties': ['Physics', 'Chemistry', 'Mathematics'],
      'assigned_classes': [
        {
          'id': 4,
          'grade': 'Form 1',
          'class_name': 'A',
          'pivot': {'subject_name': 'Physics'},
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final tResp = await apiClient.dio.get('/teachers');
      final sResp = await apiClient.dio.get('/schools');
      final cResp = await apiClient.dio.get('/school-classes');

      if (mounted) {
        setState(() {
          if (tResp.statusCode == 200 && tResp.data['status'] == 'success') {
            _teachers = List<Map<String, dynamic>>.from(
              tResp.data['teachers'] ?? [],
            );
          }
          if (sResp.statusCode == 200 && sResp.data['status'] == 'success') {
            _schools = List<Map<String, dynamic>>.from(
              sResp.data['schools'] ?? [],
            );
          }
          if (cResp.statusCode == 200 && cResp.data['status'] == 'success') {
            _classes = List<Map<String, dynamic>>.from(
              cResp.data['classes'] ?? [],
            );
          }
          _demo = false;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _demo = true;
        _teachers = _mockTeachers;
        _schools = [
          {'id': 1, 'name': 'Hillside Preparatory School'},
          {'id': 2, 'name': 'Hillside Primary School'},
          {'id': 3, 'name': 'Hillside Secondary School'},
        ];
        _classes = [
          {'id': 1, 'grade': 'ECD B', 'class_name': 'Butterflies'},
          {'id': 2, 'grade': 'Grade 1', 'class_name': 'Green'},
          {'id': 3, 'grade': 'Grade 4', 'class_name': 'Gold'},
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTeacher(int id, String name) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher Profile'),
        content: Text('Are you sure you want to delete teacher "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.dio.delete('/teachers/$id');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this teacher. Please try again.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Teacher "$name" deleted.')));
      _fetchData();
    }
  }

  bool get _canManage {
    final role = context.read<AuthProvider?>()?.user?['role'];
    return !_demo && (role == 'admin' || role == 'website_admin');
  }

  void _edit([Map<String, dynamic>? teacher]) => showDialog(
    context: context,
    builder: (_) => CreateTeacherDialog(
      initialTeacher: teacher,
      schools: _schools,
      availableClasses: _classes,
      onSaved: _fetchData,
    ),
  );
  List<dynamic> _assigned(Map<String, dynamic> teacher) =>
      teacher['assigned_classes'] as List? ?? [];
  String _name(Map<String, dynamic> teacher) =>
      '${teacher['user']?['name'] ?? 'Teacher'}';
  Widget _classList(Map<String, dynamic> teacher) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_assigned(teacher).isEmpty)
        const Text(
          'No classes assigned yet.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      for (final group in _assigned(teacher))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${group['grade']} ${group['class_name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${group['pivot']?['subject_name'] ?? 'Subject not specified'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  void _open(Map<String, dynamic> teacher) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(
                AppSymbol.teacher,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _name(teacher),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${teacher['school']?['name'] ?? 'School not provided'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                '${teacher['user']?['email'] ?? 'Email not provided'}',
                style: const TextStyle(height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                '${teacher['user']?['phone_number'] ?? 'Phone not provided'}',
              ),
              const SizedBox(height: 24),
              const Text(
                'Class assignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _classList(teacher),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) {
      final classes = _assigned(t);
      final text =
          '${_name(t)} ${t['user']?['phone_number']} ${t['school']?['name']} ${t['subject_specialties']} ${classes.map((c) => '${c['grade']} ${c['class_name']} ${c['pivot']?['subject_name']}').join(' ')}'
              .toLowerCase();
      return text.contains(_searchQuery) &&
          (_filter == 'All' ||
              (_filter == 'Assigned' ? classes.isNotEmpty : classes.isEmpty));
    }).toList();
    final classCount = _teachers
        .expand(_assigned)
        .map((c) => c['id'])
        .toSet()
        .length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Class & teacher roster'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const PageHeading(
                title: 'Class & teacher roster',
                subtitle: 'The people and classes behind every school day.',
                symbol: AppSymbol.teacher,
              ),
              PageCard(
                color: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEACHING COMMUNITY',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isLoading
                          ? 'Loading your roster…'
                          : '${_teachers.length} teachers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$classCount classes represented',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Find a teacher, explore their subjects and view class assignments.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              if (_demo)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: PageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PageBadge('Sample roster'),
                        const SizedBox(height: 10),
                        const Text(
                          'Could not connect. These are example teacher profiles.',
                        ),
                        TextButton(
                          onPressed: _fetchData,
                          child: const Text('Retry connection'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search teacher, class or subject',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              PageFilters(
                labels: const ['All', 'Assigned', 'Unassigned'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              if (_canManage)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add teacher'),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                PageCard(
                  child: Column(
                    children: [
                      const Text(
                        'No matching teachers',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Try another name, subject or class.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _filter = 'All';
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                        child: const Text('Reset filters'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  '${filtered.length} teacher profiles',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                for (final teacher in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: PageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIcon(
                            AppSymbol.teacher,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _name(teacher),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${teacher['school']?['name'] ?? 'School not provided'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final subject
                                  in (teacher['subject_specialties'] as List? ??
                                      []))
                                PageBadge('$subject'),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'CLASS ASSIGNMENTS',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _classList(teacher),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: () => _open(teacher),
                                child: const Text('View teacher details'),
                              ),
                              if (_canManage) ...[
                                TextButton(
                                  onPressed: () => _edit(teacher),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () => _deleteTeacher(
                                    teacher['id'],
                                    _name(teacher),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
