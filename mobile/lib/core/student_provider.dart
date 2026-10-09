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
    notifyListeners();
    await fetchDashboard(student['id']);
  }

  Future<void> fetchDashboard(int studentId) async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/dashboard/$studentId');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        _dashboardData = response.data;
      } else {
        _dashboardData = null;
      }
    } catch (e) {
      _dashboardData = null;
    }

    _isLoadingDashboard = false;
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
