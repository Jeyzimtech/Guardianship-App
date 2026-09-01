import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../common/app_drawer.dart';
import 'create_student_dialog.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  static const primaryBlue = AppColors.primary;
  static const borderColor = AppColors.cardBorder;

  final TextEditingController _searchController = TextEditingController();
  String _selectedClassFilter = 'all';
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _students = [
    {
      'id': 1,
      'name': 'Alice Chewe',
      'guardian': 'John Chewe (+263773333333)',
      'class_name': 'ECD B (Butterflies)',
      'attendance': '92%',
      'fee': 'USD 150.00',
      'fee_amount': 150.00,
      'status': 'outstanding',
    },
    {
      'id': 2,
      'name': 'Bob Chewe',
      'guardian': 'John Chewe (+263773333333)',
      'class_name': 'Grade 4 (Gold)',
      'attendance': '100%',
      'fee': 'USD 0.00',
      'fee_amount': 0.00,
      'status': 'paid',
    },
    {
      'id': 3,
      'name': 'Chipo Moyo',
      'guardian': 'Tariro Moyo (+263778888888)',
      'class_name': 'Grade 7 (Alpha)',
      'attendance': '96%',
      'fee': 'USD 50.00',
      'fee_amount': 50.00,
      'status': 'pending',
    },
    {
      'id': 4,
      'name': 'David Mpofu',
      'guardian': 'Sipho Mpofu (+263779999999)',
      'class_name': 'Form 1 (Green)',
      'attendance': '98%',
      'fee': 'USD 0.00',
      'fee_amount': 0.00,
      'status': 'paid',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s['name'].toString().toLowerCase().contains(q) ||
          s['guardian'].toString().toLowerCase().contains(q);

      final matchesClass = _selectedClassFilter == 'all' ||
          s['class_name'].toString().contains(_selectedClassFilter);

      final matchesStatus = _selectedStatusFilter == 'all' ||
          s['status'].toString().toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesClass && matchesStatus;
    }).toList();
  }

  Widget _buildKpiCard(String title, String value, IconData icon, {Color? valueColor, Color? iconBg, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border(
          top: BorderSide(color: primaryBlue, width: 4.0),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF1F2937))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg ?? const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor ?? primaryBlue, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF4CAF50);
        label = 'PAID';
        break;
      case 'pending':
        bg = const Color(0xFFFEF9E7);
        fg = const Color(0xFFF39C12);
        label = 'PENDING';
        break;
      case 'outstanding':
      default:
        bg = const Color(0xFFFDEDEC);
        fg = const Color(0xFFE74C3C);
        label = 'OUTSTANDING FEES';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Edu+Conect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE74C3C)),
                ),
              ],
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3 New Notifications'))),
          ),
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.chat_bubble_outline_rounded),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE74C3C)),
                ),
              ],
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('15 Unread Messages'))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'Students'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Header
            Row(
              children: [
                Text('Dashboard', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Text(' > ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text('Students', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                const Text(' > ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text('Grade 7', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            // Access Control Scope Banner
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Teacher Access Scope: View student records & fee status for assigned class. Student identity editing is managed by School Admin.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Management',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage student records, attendance & fees',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CreateStudentDialog(
                        onSaved: (newStudent) {
                          setState(() => _students.insert(0, newStudent));
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4 KPI Summary Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                _buildKpiCard('Students', '${_students.length}', Icons.school_rounded),
                _buildKpiCard('Attendance', '95%', Icons.fact_check_rounded, valueColor: const Color(0xFF4CAF50), iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
                _buildKpiCard('Outstanding', 'USD 24,000', Icons.file_present_rounded, valueColor: const Color(0xFFE74C3C), iconBg: const Color(0xFFFDEDEC), iconColor: const Color(0xFFE74C3C)),
                _buildKpiCard('Unread', '15', Icons.forum_rounded, valueColor: const Color(0xFFF39C12), iconBg: const Color(0xFFFEF9E7), iconColor: const Color(0xFFF39C12)),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Toolbar Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Search Box
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Students by name or guardian...',
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),

                  // Dropdowns & Buttons
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedClassFilter,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Class: All', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Grade 7', child: Text('Grade 7', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Grade 4', child: Text('Grade 4', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'ECD B', child: Text('ECD B', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Form 1', child: Text('Form 1', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedClassFilter = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatusFilter,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Status: All', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'paid', child: Text('Paid', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'outstanding', child: Text('Outstanding', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatusFilter = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, color: primaryBlue),
                        tooltip: 'Export CSV',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting student roster to CSV...')));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Student Cards Section (Mobile Data Table Roster)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Student Roster (${filteredList.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedClassFilter = 'all';
                      _selectedStatusFilter = 'all';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (filteredList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text('No student records match filters.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = filteredList[index];
                  final initials = s['name'].toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase();

                  return Container(
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                                  Text(s['class_name'], style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            _buildStatusBadge(s['status']),
                          ],
                        ),
                        const Divider(height: 16, color: borderColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(s['guardian'], style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937))),
                              ],
                            ),
                            Text('Att: ${s['attendance']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Balance: ${s['fee']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: primaryBlue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => CreateStudentDialog(
                                        initialStudent: s,
                                        onSaved: (updated) {
                                          setState(() {
                                            final idx = _students.indexWhere((item) => item['id'] == s['id']);
                                            if (idx != -1) _students[idx] = updated;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _students.removeWhere((item) => item['id'] == s['id']));
                                  },
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
      ),
    );
  }
}
