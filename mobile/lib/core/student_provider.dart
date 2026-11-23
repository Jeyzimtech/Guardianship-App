import 'package:flutter/material.dart';
import 'api_client.dart';

class StudentProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<dynamic> _students = [];
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _dashboardData;

  bool _isLoadingStudents = false;
  bool _isLoadingDashboard = false;
  String? _errorMessage;

  List<dynamic> get students => _students;
  Map<String, dynamic>? get selectedStudent => _selectedStudent;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get errorMessage => _errorMessage;

  StudentProvider(this.apiClient);

  Future<void> fetchStudents() async {
    _isLoadingStudents = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/students');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        _students = response.data['students'] ?? [];
        if (_students.isNotEmpty) {
          _selectedStudent = _students[0];
          await fetchDashboard(_selectedStudent!['id']);
        } else {
          _selectedStudent = null;
          _dashboardData = null;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _students = [];
      _selectedStudent = null;
      _dashboardData = null;
    }

    _isLoadingStudents = false;
    notifyListeners();
  }

  Future<void> selectStudent(Map<String, dynamic> student) async {
    _selectedStudent = student;
    _dashboardData = null;
    notifyListeners();
    await fetchDashboard(student['id']);
  }

  Future<void> fetchDashboard(int studentId) async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/dashboard/$studentId');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (_selectedStudent?['id'] != studentId) return;
        _dashboardData = Map<String, dynamic>.from(response.data);
        // Use the same records as the detail screen, including late arrivals.
        _dashboardData!.remove('attendance_snapshot');
        try {
          await fetchAttendance(studentId);
        } catch (_) {
          // Leave the metric unavailable if records could not be loaded.
        }
      } else {
        _dashboardData = null;
      }
    } catch (e) {
      _dashboardData = null;
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(int studentId) async {
    final response = await apiClient.dio.get('/attendance/$studentId');
    final rows = (response.data['attendance'] as List? ?? [])
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final attended = rows
        .where(
          (row) => [
            'present',
            'late',
          ].contains(row['status']?.toString().toLowerCase()),
        )
        .length;
    if (_selectedStudent?['id'] == studentId && _dashboardData != null) {
      _dashboardData!['attendance_snapshot'] = {
        'total_days': rows.length,
        'present_days': attended,
        'percentage': rows.isEmpty ? 0 : (attended / rows.length * 100).round(),
      };
      notifyListeners();
    }
    return rows;
  }

  void updateStudentPhoto(int studentId, String? photoUrl) {
    _students = [
      for (final student in _students)
        student['id'] == studentId
            ? {...Map<String, dynamic>.from(student), 'photo_url': photoUrl}
            : student,
    ];
    if (_selectedStudent?['id'] == studentId) {
      _selectedStudent = {..._selectedStudent!, 'photo_url': photoUrl};
    }
    notifyListeners();
  }

  void clearData() {
    _students = [];
    _selectedStudent = null;
    _dashboardData = null;
    _isLoadingStudents = false;
    _isLoadingDashboard = false;
    _errorMessage = null;
    notifyListeners();
  }
}
