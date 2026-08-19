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
        _students = response.data['students'];
        if (_students.isNotEmpty) {
          _selectedStudent = _students[0];
          await fetchDashboard(_selectedStudent!['id']);
        } else {
          _selectedStudent = null;
          _dashboardData = null;
        }
      }
    } catch (e) {
      // Offline fallback: load mock student list for John Chewe (Guardian)
      _students = [
        {
          'id': 1,
          'name': 'Alice Chewe',
          'grade': '4',
          'class_name': '4A',
        },
        {
          'id': 2,
          'name': 'Bob Chewe',
          'grade': '2',
          'class_name': '2B',
        }
      ];
      _selectedStudent = _students[0];
      await fetchDashboard(_selectedStudent!['id']);
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
      }
    } catch (e) {
      // Offline fallback: load mock dashboard data
      _dashboardData = {
        'status': 'success',
        'attendance_snapshot': {
          'percentage': studentId == 1 ? 92 : 98,
          'present_days': studentId == 1 ? 46 : 49,
          'total_days': 50,
        },
        'fee_snapshot': {
          'balance_usd': studentId == 1 ? '120.00' : '0.00',
          'balance_zig': studentId == 1 ? '350.00' : '0.00',
        },
        'z_score_trend': [
          {'term': 'Term 1', 'z_score': 1.2},
          {'term': 'Term 2', 'z_score': 1.5},
          {'term': 'Term 3', 'z_score': 1.8},
        ],
        'velocity_engine_status': studentId == 1 ? 'SLOWING' : 'OPTIMAL',
        'recent_announcements': [
          {
            'title': 'School Consultation Day',
            'content': 'Consultation day will be held this Friday. All parents are requested to attend.',
          },
          {
            'title': 'Term 2 Fee Payments',
            'content': 'Please ensure outstanding Term 2 fees are cleared to avoid reports lockout.',
          }
        ]
      };
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  Future<bool> payFees({
    required int studentId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiClient.dio.post('/fees/pay', data: {
        'student_id': studentId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        await fetchDashboard(studentId);
        return true;
      }
    } catch (_) {
      // Offline fallback: simulate fee payment in-memory
      if (_dashboardData != null && _dashboardData!['fee_snapshot'] != null) {
        final fee = _dashboardData!['fee_snapshot'];
        if (currency == 'USD') {
          double cur = double.parse(fee['balance_usd'].toString());
          fee['balance_usd'] = (cur - amount).clamp(0.0, double.infinity).toStringAsFixed(2);
        } else {
          double cur = double.parse(fee['balance_zig'].toString());
          fee['balance_zig'] = (cur - amount).clamp(0.0, double.infinity).toStringAsFixed(0);
        }
        notifyListeners();
        return true;
      }
    }
    return false;
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
