import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';

class TeacherSosCard extends StatefulWidget {
  const TeacherSosCard({super.key});
  @override
  State<TeacherSosCard> createState() => _TeacherSosCardState();
}

class _TeacherSosCardState extends State<TeacherSosCard> {
  bool _busy = false;
  String? _requestId;
  String? _pendingMessage;
  List<int>? _pendingGuardianIds;
  bool? _pendingEveryone;

  String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<List<dynamic>?> _loadParents() async {
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/messages/contacts',
      );
      return response.data['contacts'] as List<dynamic>? ?? [];
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load parents. Try again.')),
        );
      }
      return null;
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final parents = await _loadParents();
    if (!mounted) return;
    setState(() => _busy = false);
    if (parents == null) return;
    final locked = _pendingMessage != null;
    final selected = <int>{...?_pendingGuardianIds};
    var everyone = _pendingEveryone ?? false;
    var query = '';
    final message = TextEditingController(
      text:
          _pendingMessage ??
          'An emergency has been reported. Please contact the school immediately.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final visible = parents.where((s) {
            final name =
                '${s['name']} ${(s['students'] as List? ?? []).join(' ')}'
                    .toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();
          return AlertDialog(
            title: const Text('Send emergency SOS?'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('One parent')),
                        ButtonSegment(value: true, label: Text('All parents')),
                      ],
                      selected: {everyone},
                      showSelectedIcon: false,
                      onSelectionChanged: locked
                          ? null
                          : (value) =>
                                setDialogState(() => everyone = value.first),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      everyone
                          ? 'All ${parents.length} parents linked to your assigned classes will receive this SOS. This uses SMS credits for every recipient.'
                          : 'Choose the parent of the child facing a challenge. Only that parent receives the SOS and SMS.',
                    ),
                    const SizedBox(height: 16),
                    if (!locked && !everyone)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search parent or child',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (v) => setDialogState(() => query = v),
                      ),
                    const SizedBox(height: 8),
                    if (everyone)
                      const SizedBox.shrink()
                    else if (parents.isEmpty)
                      const Text(
                        'No parents linked to your assigned classes yet.',
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final s in visible)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: selected.contains(s['id']),
                                title: Text('${s['name']}'),
                                subtitle: Text(
                                  'Parent of ${(s['students'] as List? ?? []).join(', ')}',
                                ),
                                onChanged: locked
                                    ? null
                                    : (v) => setDialogState(() {
                                        selected.clear();
                                        if (v == true) {
                                          selected.add(s['id'] as int);
                                        }
                                      }),
                              ),
                          ],
                        ),
                      ),
                    if (!everyone)
                      Text(
                        selected.isEmpty
                            ? 'Select one parent'
                            : '1 parent selected',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: message,
                      maxLength: 500,
                      maxLines: 4,
                      readOnly: locked,
                      decoration: const InputDecoration(
                        labelText: 'Emergency message',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (everyone ? parents.isEmpty : selected.isEmpty)
                    ? null
                    : () {
                        if (message.text.trim().isNotEmpty) {
                          Navigator.pop(ctx, true);
                        }
                      },
                child: Text(everyone ? 'Review all parents' : 'Send SOS'),
              ),
            ],
          );
        },
      ),
    );
    final text = message.text.trim();
    // The field remains mounted during its route exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    message.dispose();
    if (confirmed != true || !mounted) return;
    if (everyone && !locked) {
      final sendToAll = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Send SOS to all ${parents.length} parents?'),
          content: const Text(
            'Every parent linked to your assigned classes will receive this alert. SMS will use school credits for all recipients. Continue only if every family needs this emergency alert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send to all parents'),
            ),
          ],
        ),
      );
      if (sendToAll != true || !mounted) return;
    }
    _requestId ??= _uuid();
    _pendingMessage ??= text;
    _pendingGuardianIds ??= selected.toList();
    _pendingEveryone ??= everyone;
    setState(() => _busy = true);
    String result;
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/sos',
        data: {
          'request_id': _requestId,
          'message': _pendingMessage,
          if (_pendingEveryone!)
            'audience': 'all'
          else
            'guardian_ids': _pendingGuardianIds,
        },
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      result =
          '${response.data['message']} (${response.data['recipients']} parents)';
      _requestId = null;
      _pendingMessage = null;
      _pendingGuardianIds = null;
      _pendingEveryone = null;
    } catch (e) {
      result = e is DioException && e.response?.data is Map
          ? e.response!.data['message']?.toString() ??
                'SOS could not be confirmed.'
          : 'SOS could not be confirmed. Retry to check this same alert, or call the school.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SOS status'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLASSROOM SAFETY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Emergency SOS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send an urgent app alert and SMS to one parent. For emergencies affecting every family, choose all parents and review before sending.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.sos_outlined),
            label: Text(
              _busy
                  ? 'Sending SOS...'
                  : _requestId != null
                  ? 'Check / retry SOS'
                  : 'Choose SOS recipients',
            ),
          ),
        ],
      ),
    ),
  );
}
