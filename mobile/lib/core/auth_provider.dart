import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _user?['role'] == 'admin';
  bool get isTeacher => _user?['role'] == 'teacher';
  bool get isGuardian => _user?['role'] == 'guardian';

  AuthProvider(this.apiClient) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    final role = prefs.getString('user_role');
    final phone = prefs.getString('user_phone');
    
    if (_token != null && role != null) {
      if (role == 'admin' || role == 'website_admin') {
        _token = null;
        _user = null;
        await prefs.remove('auth_token');
        await prefs.remove('user_name');
        await prefs.remove('user_role');
        await prefs.remove('user_phone');
        notifyListeners();
        return;
      }

      _user = {
        'name': name,
        'role': role,
        'phone_number': phone,
      };
      notifyListeners();
    }
  }

  Future<bool> loginWithFirebaseToken(String firebaseIdToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.dio.post('/auth/firebase-login', data: {
        'id_token': firebaseIdToken,
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final userRole = response.data['user']?['role'];
        if (userRole == 'admin' || userRole == 'website_admin') {
          _token = null;
          _user = null;
          _errorMessage = 'Mobile application access is restricted to Teachers and Parents/Students only. Please log in via the Web Admin Portal.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _token = response.data['token'];
        _user = response.data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_name', _user!['name'] ?? '');
        await prefs.setString('user_role', _user!['role'] ?? '');
        await prefs.setString('user_phone', _user!['phone_number'] ?? '');

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Offline fallback: simulate successful login for prototype (Teacher or Guardian)
      final isTeacherRole = firebaseIdToken.contains('teacher') || firebaseIdToken.contains('+263772222222');
      final role = isTeacherRole ? 'teacher' : 'guardian';
      final name = isTeacherRole ? 'Teacher Grace' : 'Guardian John Chewe';
      final phone = isTeacherRole ? '+263772222222' : '+263773333333';

      _token = 'mock-local-token-123456';
      _user = {
        'name': name,
        'role': role,
        'phone_number': phone,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_name', _user!['name'] ?? '');
      await prefs.setString('user_role', _user!['role'] ?? '');
      await prefs.setString('user_phone', _user!['phone_number'] ?? '');

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    }

    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    
    notifyListeners();
  }
}
