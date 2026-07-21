import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import 'create_academic_year_dialog.dart';
import 'create_class_dialog.dart';
import 'create_school_dialog.dart';

class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> with SingleTickerProviderStateMixin {
  static const darkTeal = Color(0xFF0B2144);
  static const mintGreen = Color(0xFF2563EB);

  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _classes = [];

  // Mock data fallbacks for offline/demo mode
  final List<Map<String, dynamic>> _mockSchools = [
    {'id': 1, 'name': 'Hillside Preparatory School', 'type': 'prep', 'students_count': 45, 'teachers_count': 4, 'school_classes_count': 3},
    {'id': 2, 'name': 'Hillside Primary School', 'type': 'primary', 'students_count': 230, 'teachers_count': 12, 'school_classes_count': 14},
    {'id': 3, 'name': 'Hillside Secondary School', 'type': 'secondary', 'students_count': 310, 'teachers_count': 18, 'school_classes_count': 18},
  ];

  final List<Map<String, dynamic>> _mockAcademicYears = [
    {'id': 1, 'name': 'Term 1 2026', 'code': 'AY-2026-T1', 'is_current': true, 'school_classes_count': 35},
    {'id': 2, 'name': 'Term 3 2025', 'code': 'AY-2025-T3', 'is_current': false, 'school_classes_count': 35},
  ];

  final List<Map<String, dynamic>> _mockClasses = [
    {'id': 1, 'school_id': 1, 'grade': 'ECD B', 'class_name': 'Butterflies', 'capacity': 25, 'school': {'name': 'Hillside Preparatory School'}},
    {'id': 2, 'school_id': 2, 'grade': 'Grade 1', 'class_name': 'Green', 'capacity': 30, 'school': {'name': 'Hillside Primary School'}},
    {'id': 3, 'school_id': 2, 'grade': 'Grade 4', 'class_name': 'Gold', 'capacity': 35, 'school': {'name': 'Hillside Primary School'}},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            _schools = List<Map<String, dynamic>>.from(sResp.data['schools'] ?? []);
          }
          if (ayResp.statusCode == 200 && ayResp.data['status'] == 'success') {
            _academicYears = List<Map<String, dynamic>>.from(ayResp.data['academic_years'] ?? []);
          }
          if (cResp.statusCode == 200 && cResp.data['status'] == 'success') {
            _classes = List<Map<String, dynamic>>.from(cResp.data['classes'] ?? []);
          }
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Fallback to offline mock data
    }

    if (mounted) {
      setState(() {
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (type == 'School') await apiClient.dio.delete('/schools/$id');
      if (type == 'Academic Term') await apiClient.dio.delete('/academic-years/$id');
      if (type == 'Class') await apiClient.dio.delete('/school-classes/$id');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type "$name" deleted.')));
      _fetchAllData();
    }
  }

  Future<void> _setActiveAcademicYear(int id, String name) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    try {
      await apiClient.dio.post('/academic-years/$id/set-current');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Active term set to "$name"')));
      _fetchAllData();
    }
  }

  Widget _buildSchoolTypeBadge(String type) {
    Color bg;
    Color fg;
    String label;

    switch (type.toLowerCase()) {
      case 'prep':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Prep / ECD';
        break;
      case 'primary':
        bg = const Color(0xFFE6F9F5);
        fg = const Color(0xFF05D099);
        label = 'Primary School';
        break;
      case 'secondary':
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        label = 'Secondary High';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'School Management',
          style: TextStyle(color: darkTeal, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: darkTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: mintGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Campuses'),
            Tab(text: 'Academic Terms'),
            Tab(text: 'Grades & Classes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mintGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabController.index == 0
              ? 'Add Campus'
              : (_tabController.index == 1 ? 'Add Term' : 'Add Class'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            showDialog(context: context, builder: (_) => CreateSchoolDialog(onSaved: _fetchAllData));
          } else if (_tabController.index == 1) {
            showDialog(context: context, builder: (_) => CreateAcademicYearDialog(onSaved: _fetchAllData));
          } else {
            showDialog(
              context: context,
              builder: (_) => CreateClassDialog(
                schools: _schools,
                academicYears: _academicYears,
                onSaved: _fetchAllData,
              ),
            );
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: darkTeal))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Schools List Tab
                _buildSchoolsTab(),

                // 2. Academic Years List Tab
                _buildAcademicYearsTab(),

                // 3. Grades & Classes List Tab
                _buildClassesTab(),
              ],
            ),
    );
  }

  Widget _buildSchoolsTab() {
    if (_schools.isEmpty) {
      return const Center(child: Text('No schools configured yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _schools.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final school = _schools[index];
        final id = school['id'] ?? 0;
        final name = school['name'] ?? 'School';
        final type = school['type'] ?? 'primary';
        final sCount = school['students_count'] ?? 0;
        final tCount = school['teachers_count'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: darkTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: darkTeal, size: 28),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal)),
                ),
                const SizedBox(width: 8),
                _buildSchoolTypeBadge(type),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('$sCount Students', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(width: 16),
                  Icon(Icons.badge_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('$tCount Teachers', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  showDialog(context: context, builder: (_) => CreateSchoolDialog(initialSchool: school, onSaved: _fetchAllData));
                } else if (val == 'delete') {
                  _deleteItem('School', id, name);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: darkTeal), SizedBox(width: 8), Text('Edit School')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete School', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicYearsTab() {
    if (_academicYears.isEmpty) {
      return const Center(child: Text('No academic terms configured yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _academicYears.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final year = _academicYears[index];
        final id = year['id'] ?? 0;
        final name = year['name'] ?? 'Academic Term';
        final code = year['code'] ?? '';
        final isCurrent = year['is_current'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCurrent ? mintGreen : const Color(0xFFE5E7EB), width: isCurrent ? 2 : 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Icon(Icons.date_range_rounded, color: isCurrent ? mintGreen : darkTeal, size: 32),
            title: Row(
              children: [
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal)),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE6F9F5), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Active Term', style: TextStyle(color: mintGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ],
            ),
            subtitle: Text('Code: $code', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'active') {
                  _setActiveAcademicYear(id, name);
                } else if (val == 'edit') {
                  showDialog(context: context, builder: (_) => CreateAcademicYearDialog(initialYear: year, onSaved: _fetchAllData));
                } else if (val == 'delete') {
                  _deleteItem('Academic Term', id, name);
                }
              },
              itemBuilder: (ctx) => [
                if (!isCurrent)
                  const PopupMenuItem(value: 'active', child: Row(children: [Icon(Icons.check_circle_outline, color: mintGreen), SizedBox(width: 8), Text('Set Active Term')])),
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: darkTeal), SizedBox(width: 8), Text('Edit Term')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Term', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassesTab() {
    if (_classes.isEmpty) {
      return const Center(child: Text('No grade classes configured yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _classes[index];
        final id = item['id'] ?? 0;
        final grade = item['grade'] ?? 'Grade';
        final className = item['class_name'] ?? 'Class';
        final schoolName = item['school']?['name'] ?? 'School';
        final capacity = item['capacity'] ?? 30;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Text(grade.isNotEmpty ? grade[0] : 'G', style: const TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
            ),
            title: Text('$grade - $className', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal)),
            subtitle: Text('$schoolName • Max Capacity: $capacity students', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  showDialog(
                    context: context,
                    builder: (_) => CreateClassDialog(
                      schools: _schools,
                      academicYears: _academicYears,
                      initialClass: item,
                      onSaved: _fetchAllData,
                    ),
                  );
                } else if (val == 'delete') {
                  _deleteItem('Class', id, '$grade $className');
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: darkTeal), SizedBox(width: 8), Text('Edit Class')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Class', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }
}
