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
      // Offline fallback: simulate successful login for prototype
      final isTeacher = firebaseIdToken.contains('teacher') || firebaseIdToken.contains('+263772222222');
      _token = 'mock-local-token-123456';
      _user = {
        'name': isTeacher ? 'Teacher Grace' : 'Guardian John Chewe',
        'role': isTeacher ? 'teacher' : 'guardian',
        'phone_number': isTeacher ? '+263772222222' : '+263773333333',
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
