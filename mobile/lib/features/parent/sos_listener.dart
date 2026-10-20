import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

/// Foreground alarm. SMS is the independent channel when the app is closed/offline.
class SosListener extends StatefulWidget {
  final Widget child;
  const SosListener({super.key, required this.child});
  @override
  State<SosListener> createState() => _SosListenerState();
}

class _SosListenerState extends State<SosListener> with WidgetsBindingObserver {
  Timer? _poller;
  bool _checking = false;
  bool _showing = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _poller = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted || !_active || _checking || _showing) return;
    _checking = true;
    try {
      final api = context.read<AuthProvider>().apiClient;
      final response = await api.dio.get('/sos');
      final alerts = response.data['alerts'] as List? ?? [];
      if (!mounted || alerts.isEmpty || !_active) return;
      final alert = alerts.first;
      _showing = true;
      void sound() {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      }

      sound();
      final alarm = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_active) sound();
      });
      bool acknowledging = false;
      String? error;
      try {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                title: const Text('Emergency SOS'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert['message'].toString()),
                    const SizedBox(height: 16),
                    Text('From ${alert['teacher_name']}'),
                    const Text('Contact your school immediately.'),
                    if (error != null) Text(error!),
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: acknowledging
                        ? null
                        : () async {
                            update(() {
                              acknowledging = true;
                              error = null;
                            });
                            try {
                              await api.dio.post(
                                '/sos/${alert['id']}/acknowledge',
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (_) {
                              if (ctx.mounted) {
                                update(() {
                                  acknowledging = false;
                                  error =
                                      'Could not acknowledge. Please try again.';
                                });
                              }
                            }
                          },
                    child: Text(
                      acknowledging ? 'Saving...' : 'I have seen this alert',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } finally {
        alarm.cancel();
        _showing = false;
      }
    } catch (_) {
      // Preserve pending alerts server-side until the next successful connection.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
