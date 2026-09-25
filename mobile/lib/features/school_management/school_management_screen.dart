import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import 'create_academic_year_dialog.dart';
import 'create_class_dialog.dart';
import 'create_school_dialog.dart';

class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> {
  String _tab = 'Campuses';
  String _query = '';
  bool _demo = false;
  final _search = TextEditingController();
  bool _isLoading = true;

  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _classes = [];

  // Mock data fallbacks for offline/demo mode
  final List<Map<String, dynamic>> _mockSchools = [
    {
      'id': 1,
      'name': 'Hillside Preparatory School',
      'type': 'prep',
      'students_count': 45,
      'teachers_count': 4,
      'school_classes_count': 3,
    },
    {
      'id': 2,
      'name': 'Hillside Primary School',
      'type': 'primary',
      'students_count': 230,
      'teachers_count': 12,
      'school_classes_count': 14,
    },
    {
      'id': 3,
      'name': 'Hillside Secondary School',
      'type': 'secondary',
      'students_count': 310,
      'teachers_count': 18,
      'school_classes_count': 18,
    },
  ];

  final List<Map<String, dynamic>> _mockAcademicYears = [
    {
      'id': 1,
      'name': 'Term 1 2026',
      'code': 'AY-2026-T1',
      'is_current': true,
      'school_classes_count': 35,
    },
    {
      'id': 2,
      'name': 'Term 3 2025',
      'code': 'AY-2025-T3',
      'is_current': false,
      'school_classes_count': 35,
    },
  ];

  final List<Map<String, dynamic>> _mockClasses = [
    {
      'id': 1,
      'school_id': 1,
      'grade': 'ECD B',
      'class_name': 'Butterflies',
      'capacity': 25,
      'school': {'name': 'Hillside Preparatory School'},
    },
    {
      'id': 2,
      'school_id': 2,
      'grade': 'Grade 1',
      'class_name': 'Green',
      'capacity': 30,
      'school': {'name': 'Hillside Primary School'},
    },
    {
      'id': 3,
      'school_id': 2,
      'grade': 'Grade 4',
      'class_name': 'Gold',
      'capacity': 35,
      'school': {'name': 'Hillside Primary School'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final sResp = await apiClient.dio.get('/schools');
      final ayResp = await apiClient.dio.get('/academic-years');
      final cResp = await apiClient.dio.get('/school-classes');

      if (mounted) {
        setState(() {
          if (sResp.statusCode == 200 && sResp.data['status'] == 'success') {
            _schools = List<Map<String, dynamic>>.from(
              sResp.data['schools'] ?? [],
            );
          }
          if (ayResp.statusCode == 200 && ayResp.data['status'] == 'success') {
            _academicYears = List<Map<String, dynamic>>.from(
              ayResp.data['academic_years'] ?? [],
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
    } catch (_) {
      // Fallback to offline mock data
    }

    if (mounted) {
      setState(() {
        _demo = true;
        _schools = _mockSchools;
        _academicYears = _mockAcademicYears;
        _classes = _mockClasses;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String type, int id, String name) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete "$name"?'),
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
      if (type == 'School') await apiClient.dio.delete('/schools/$id');
      if (type == 'Academic Term') {
        await apiClient.dio.delete('/academic-years/$id');
      }
      if (type == 'Class') await apiClient.dio.delete('/school-classes/$id');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please try again.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$type "$name" deleted.')));
      _fetchAllData();
    }
  }

  Future<void> _setActiveAcademicYear(int id, String name) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    try {
      await apiClient.dio.post('/academic-years/$id/set-current');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please try again.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Active term set to "$name"')));
      _fetchAllData();
    }
  }

  bool get _canManage {
    final role = context.read<AuthProvider?>()?.user?['role'];
    return !_demo && (role == 'admin' || role == 'website_admin');
  }

  void _edit([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (_) => _tab == 'Campuses'
          ? CreateSchoolDialog(initialSchool: item, onSaved: _fetchAllData)
          : _tab == 'Terms'
          ? CreateAcademicYearDialog(initialYear: item, onSaved: _fetchAllData)
          : CreateClassDialog(
              schools: _schools,
              academicYears: _academicYears,
              initialClass: item,
              onSaved: _fetchAllData,
            ),
    );
  }

  String _name(Map<String, dynamic> item) => _tab == 'Classes'
      ? '${item['grade']} ${item['class_name']}'
      : '${item['name'] ?? 'Not provided'}';
  String _type(Map<String, dynamic> item) => switch (item['type']) {
    'prep' => 'Preparatory',
    'primary' => 'Primary',
    'secondary' => 'Secondary',
    _ => 'School',
  };
  bool _active(Map<String, dynamic> item) =>
      item['is_current'] == true || item['is_current'] == 1;
  Widget _details(Map<String, dynamic> item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_tab == 'Campuses')
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _metric('${item['students_count'] ?? '—'}', 'Students'),
            _metric('${item['teachers_count'] ?? '—'}', 'Teachers'),
            _metric('${item['school_classes_count'] ?? '—'}', 'Classes'),
          ],
        ),
      if (_tab == 'Terms') ...[
        Text(
          'Term code · ${item['code'] ?? 'Not provided'}',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        if (item['start_date'] != null)
          Text(
            'Starts ${item['start_date']}',
            style: const TextStyle(height: 1.5),
          ),
        if (item['end_date'] != null)
          Text('Ends ${item['end_date']}', style: const TextStyle(height: 1.5)),
      ],
      if (_tab == 'Classes') ...[
        Text(
          '${item['school']?['name'] ?? 'School not provided'}',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 12),
        PageBadge('Capacity · ${item['capacity'] ?? 'Not provided'} students'),
        if (item['academic_year']?['name'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('${item['academic_year']['name']}'),
          ),
      ],
    ],
  );
  Widget _metric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    ],
  );
  void _open(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
                  AppSymbol.school,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 18),
                Text(
                  _name(item),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _details(item),
                const SizedBox(height: 24),
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
  }

  @override
  Widget build(BuildContext context) {
    final items = _tab == 'Campuses'
        ? _schools
        : _tab == 'Terms'
        ? _academicYears
        : _classes;
    final filtered = items
        .where(
          (i) => '${_name(i)} ${i['school']?['name'] ?? ''} ${i['code'] ?? ''}'
              .toLowerCase()
              .contains(_query),
        )
        .toList();
    final current = _academicYears.where(_active).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'School management'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAllData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const PageHeading(
                title: 'School management',
                subtitle: 'Your school community, clearly organised.',
                symbol: AppSymbol.school,
              ),
              PageCard(
                color: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACADEMIC OVERVIEW',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'Loading school details…'
                          : current.isEmpty
                          ? 'No active term'
                          : '${current.first['name']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_schools.length} campuses · ${_classes.length} classes',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
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
                        const PageBadge('Sample data'),
                        const SizedBox(height: 10),
                        const Text(
                          'Could not connect to your school. These are example records.',
                          style: TextStyle(height: 1.5),
                        ),
                        TextButton(
                          onPressed: _fetchAllData,
                          child: const Text('Retry connection'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              PageFilters(
                labels: const ['Campuses', 'Terms', 'Classes'],
                selected: _tab,
                onSelected: (v) => setState(() {
                  _tab = v;
                  _query = '';
                  _search.clear();
                }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search ${_tab.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              if (_canManage) ...[
                FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    _tab == 'Campuses'
                        ? 'Add campus'
                        : _tab == 'Terms'
                        ? 'Add term'
                        : 'Add class',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const PageEmpty(
                  title: 'No matching records',
                  message: 'Try another search or pull down to refresh.',
                )
              else ...[
                Text(
                  '${filtered.length} ${_tab.toLowerCase()}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PageBadge(
                            _tab == 'Campuses'
                                ? _type(item)
                                : _tab == 'Terms'
                                ? (_active(item)
                                      ? 'Active term'
                                      : 'Academic term')
                                : '${item['grade']}',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _name(item),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _details(item),
                          const SizedBox(height: 18),
                          const Divider(height: 1),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: () => _open(item),
                                child: const Text('View details'),
                              ),
                              if (_canManage) ...[
                                TextButton(
                                  onPressed: () => _edit(item),
                                  child: const Text('Edit'),
                                ),
                                if (_tab == 'Terms' && !_active(item))
                                  TextButton(
                                    onPressed: () => _setActiveAcademicYear(
                                      item['id'],
                                      _name(item),
                                    ),
                                    child: const Text('Set active'),
                                  ),
                                TextButton(
                                  onPressed: () => _deleteItem(
                                    _tab == 'Campuses'
                                        ? 'School'
                                        : _tab == 'Terms'
                                        ? 'Academic Term'
                                        : 'Class',
                                    item['id'],
                                    _name(item),
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
