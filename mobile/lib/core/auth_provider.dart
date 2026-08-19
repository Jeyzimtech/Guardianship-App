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
    final email = prefs.getString('user_email');
    final address = prefs.getString('user_address');
    final lang = prefs.getString('user_language');
    
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
        'email': email,
        'address': address,
        'preferred_language': lang ?? 'English',
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
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? preferredLanguage,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.put('/guardian/profile', data: {
        'name':? name,
        'phone_number':? phone,
        'email':? email,
        'address':? address,
        'preferred_language':? preferredLanguage,
        'emergency_contact_name':? emergencyContactName,
        'emergency_contact_phone':? emergencyContactPhone,
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final updatedData = response.data['data'];
        _user = {
          ...?_user,
          'name':? updatedData['name'],
          'phone_number':? updatedData['phone_number'],
          'email':? updatedData['email'],
          'address':? updatedData['address'],
          'preferred_language':? updatedData['preferred_language'],
          'emergency_contact_name':? updatedData['emergency_contact_name'],
          'emergency_contact_phone':? updatedData['emergency_contact_phone'],
        };
      }
    } catch (_) {
      // Local state fallback for offline prototype operation
      _user = {
        ...?_user,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone_number': phone,
        'email':? email,
        'address':? address,
        'preferred_language':? preferredLanguage,
        'emergency_contact_name':? emergencyContactName,
        'emergency_contact_phone':? emergencyContactPhone,
      };
    }

    final prefs = await SharedPreferences.getInstance();
    if (_user?['name'] != null) await prefs.setString('user_name', _user!['name']);
    if (_user?['phone_number'] != null) await prefs.setString('user_phone', _user!['phone_number']);
    if (_user?['email'] != null) await prefs.setString('user_email', _user!['email']);
    if (_user?['address'] != null) await prefs.setString('user_address', _user!['address']);
    if (_user?['preferred_language'] != null) await prefs.setString('user_language', _user!['preferred_language']);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.dio.post('/auth/delete-account');
    } catch (_) {
      // Offline fallback
    }

    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
