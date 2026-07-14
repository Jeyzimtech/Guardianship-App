import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  List<dynamic> _attendance = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final selectedStudent = studentProvider.selectedStudent;
    if (selectedStudent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get('/attendance/${selectedStudent['id']}');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _attendance = response.data['attendance'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load attendance records.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const cardBgColor = Color(0xFF1B263B);
    const darkBlueColor = Color(0xFF0F1E36);

    return Scaffold(
      backgroundColor: darkBlueColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: vanillaColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _fetchAttendance,
                  color: vanillaColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _attendance.isEmpty ? 1 : _attendance.length,
                    itemBuilder: (context, index) {
                      if (_attendance.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Column(
                              children: [
                                Icon(Icons.calendar_month_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No attendance data logged yet.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final record = _attendance[index];
                      final isPresent = record['status'] == 'present';

                      return Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Icon(
                            isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isPresent ? Colors.greenAccent : Colors.redAccent,
                            size: 28,
                          ),
                          title: Text(
                            record['date'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            record['subject_name'] != null
                                ? 'Subject: ${record['subject_name']}'
                                : 'Daily Roster',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                color: isPresent ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
