import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  AuthProvider? _auth;
  String? _identity;
  Timer? _timer;
  int _generation = 0;
  bool loading = true;
  bool allowed = false;
  String? error;
  List<Map<String, dynamic>> children = [];

  void bind(AuthProvider auth) {
    final identity = auth.isAuthenticated && auth.isGuardian
        ? '${auth.user?['id']}:${auth.token}'
        : null;
    if (identity == _identity) return;
    _identity = identity;
    _auth = auth;
    _generation++;
    _timer?.cancel();
    children = [];
    allowed = false;
    loading = identity != null;
    error = null;
    if (identity == null) return;
    scheduleMicrotask(refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_identity == null) return;
    final generation = _generation;
    try {
      final response = await _auth!.apiClient.dio.get('/subscription');
      if (generation != _generation) return;
      allowed = response.data['access_allowed'] == true;
      children = (response.data['children'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      error = null;
    } catch (_) {
      if (generation != _generation) return;
      error = 'We could not check your subscription. Please try again.';
      allowed = false;
    }
    loading = false;
    notifyListeners();
  }

  InterceptorsWrapper get interceptor => InterceptorsWrapper(
    onError: (e, h) {
      if (e.response?.data is Map &&
          e.response?.data['code'] == 'subscription_suspended') {
        allowed = false;
        notifyListeners();
        refresh();
      }
      h.next(e);
    },
  );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
