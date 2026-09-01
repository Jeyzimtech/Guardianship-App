import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import 'create_teacher_dialog.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  static const darkTeal = AppColors.primary;
  static const mintGreen = AppColors.primaryLight;

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
        {'id': 2, 'grade': 'Grade 1', 'class_name': 'Green', 'pivot': {'subject_name': 'Homeroom'}},
        {'id': 3, 'grade': 'Grade 4', 'class_name': 'Gold', 'pivot': {'subject_name': 'Mathematics'}},
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
        {'id': 4, 'grade': 'Form 1', 'class_name': 'A', 'pivot': {'subject_name': 'Physics'}},
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
      final tResp = await apiClient.dio.get('/teachers', queryParameters: _searchQuery.isNotEmpty ? {'search': _searchQuery} : null);
      final sResp = await apiClient.dio.get('/schools');
      final cResp = await apiClient.dio.get('/school-classes');

      if (mounted) {
        setState(() {
          if (tResp.statusCode == 200 && tResp.data['status'] == 'success') {
            _teachers = List<Map<String, dynamic>>.from(tResp.data['teachers'] ?? []);
          }
          if (sResp.statusCode == 200 && sResp.data['status'] == 'success') {
            _schools = List<Map<String, dynamic>>.from(sResp.data['schools'] ?? []);
          }
          if (cResp.statusCode == 200 && cResp.data['status'] == 'success') {
            _classes = List<Map<String, dynamic>>.from(cResp.data['classes'] ?? []);
          }
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      var filtered = _mockTeachers;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        filtered = filtered.where((t) {
          final u = t['user'] ?? {};
          return u['name'].toString().toLowerCase().contains(q) ||
                 u['phone_number'].toString().toLowerCase().contains(q);
        }).toList();
      }

      setState(() {
        _teachers = filtered;
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
      await apiClient.dio.delete('/teachers/$id');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Teacher "$name" deleted.')));
      _fetchData();
    }
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
          'Teacher Management',
          style: TextStyle(color: darkTeal, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mintGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CreateTeacherDialog(
              schools: _schools,
              availableClasses: _classes,
              onSaved: _fetchData,
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teacher by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: darkTeal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _fetchData();
              },
            ),
            const SizedBox(height: 16),

            // Teacher list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: darkTeal))
                  : _teachers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('No teachers found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _teachers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            final id = teacher['id'] ?? 0;
                            final user = teacher['user'] ?? {};
                            final name = user['name'] ?? 'Teacher';
                            final email = user['email'] ?? 'No email';
                            final phone = user['phone_number'] ?? 'No phone';
                            final schoolName = teacher['school']?['name'] ?? 'Hillside School';

                            List specialties = [];
                            if (teacher['subject_specialties'] != null && teacher['subject_specialties'] is List) {
                              specialties = teacher['subject_specialties'];
                            }

                            List assignedClasses = [];
                            if (teacher['assigned_classes'] != null && teacher['assigned_classes'] is List) {
                              assignedClasses = teacher['assigned_classes'];
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFFE6F4F1),
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal)),
                                              const SizedBox(height: 2),
                                              Text(schoolName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              showDialog(
                                                context: context,
                                                builder: (_) => CreateTeacherDialog(
                                                  initialTeacher: teacher,
                                                  schools: _schools,
                                                  availableClasses: _classes,
                                                  onSaved: _fetchData,
                                                ),
                                              );
                                            } else if (val == 'delete') {
                                              _deleteTeacher(id, name);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: darkTeal), SizedBox(width: 8), Text('Edit Profile')])),
                                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Teacher', style: TextStyle(color: Colors.red))])),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Phone & Email
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(phone, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Specialties
                                    if (specialties.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: specialties.map((s) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                                            child: Text(s.toString(), style: const TextStyle(fontSize: 11, color: darkTeal, fontWeight: FontWeight.w600)),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    // Assigned Classes
                                    if (assignedClasses.isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.meeting_room_outlined, size: 16, color: mintGreen),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Assigned: ${assignedClasses.map((ac) {
                                                      final g = ac['grade'] ?? '';
                                                      final cn = ac['class_name'] ?? '';
                                                      final subj = ac['pivot']?['subject_name'] ?? '';
                                                      return '$g $cn ($subj)';
                                                    }).join(', ')}',
                                                style: const TextStyle(fontSize: 12, color: darkTeal, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
