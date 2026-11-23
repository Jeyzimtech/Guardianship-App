import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_provider.dart';

/// Server-owned unread state shared by tabs, drawer and pushed updates.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  AuthProvider? _auth;
  String? _session;
  Timer? _timer;
  bool _fetching = false;
  Map<String, int> _counts = {};
  Set<String> noticeReads = {};
  int count(String category) => _counts[category] ?? 0;

  NotificationProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  void bind(AuthProvider auth) {
    _auth = auth;
    if (_session == auth.token) return;
    _session = auth.token;
    _counts = {};
    noticeReads = {};
    _timer?.cancel();
    if (_session != null) {
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => refresh());
      scheduleMicrotask(refresh);
    }
  }

  Future<void> refresh() async {
    final session = _session;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (session == null ||
        _fetching ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    _fetching = true;
    try {
      final response = await _auth!.apiClient.dio.get(
        '/mobile-notifications/counts',
      );
      if (_session != session) return;
      noticeReads = (response.data['notice_reads'] as List? ?? [])
          .map((id) => '$id')
          .toSet();
      final counts = response.data['counts'] as Map;
      _counts = counts.map(
        (key, value) => MapEntry('$key', (value as num).toInt()),
      );
      notifyListeners();
    } catch (_) {
      // Keep the last known counts offline; never clear unread on a failed request.
    } finally {
      _fetching = false;
    }
  }

  Future<void> markRead(String category, Iterable<int> ids) async {
    final list = ids.toSet().toList();
    if (_session == null || list.isEmpty) return;
    try {
      for (var start = 0; start < list.length; start += 1000) {
        await _auth!.apiClient.dio.post(
          '/mobile-notifications/read',
          data: {
            'category': category,
            'ids': list.skip(start).take(1000).toList(),
          },
        );
      }
      await refresh();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
