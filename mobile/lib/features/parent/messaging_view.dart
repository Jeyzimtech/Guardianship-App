import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/auth_provider.dart';
import '../chat/chat_view.dart';
import '../chat/message_status.dart';
import '../common/page_components.dart';
import '../dashboard/announcements_view.dart';

/// Conversations between teachers and the parents of their assigned classes.
class MessagingView extends StatefulWidget {
  const MessagingView({super.key});

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final _search = TextEditingController();
  Timer? _poller;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        _fetching ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    _fetching = true;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/messages/contacts',
      );
      if (!mounted) return;
      setState(() {
        _error = null;
        _contacts = (response.data['contacts'] as List? ?? [])
            .map((c) => Map<String, dynamic>.from(c))
            .toList();
      });
    } catch (_) {
      if (mounted && (!silent || _contacts.isEmpty)) {
        setState(
          () => _error =
              'Unable to load conversations. Check your connection and try again.',
        );
      }
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openConversation(Map<String, dynamic> contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationView(contact: contact)),
    );
    if (mounted) _load();
  }

  Future<void> _compose() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ComposeMessagePage(parents: _contacts)),
    );
    if (sent == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.watch<AuthProvider>().isTeacher;
    final filtered = _contacts
        .where(
          (c) => '${c['name']} ${(c['students'] as List? ?? []).join(' ')}'
              .toLowerCase()
              .contains(_query),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Messages'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              PageHeading(
                title: 'Messages',
                subtitle: isTeacher
                    ? 'Messages expire after 7 days. Write to one family or to every parent in your classes.'
                    : 'Messages expire after 7 days. Keep in touch with your child’s teachers.',
                symbol: AppSymbol.message,
              ),
              if (isTeacher) ...[
                FilledButton(
                  onPressed: _loading || _contacts.isEmpty ? null : _compose,
                  child: const Text('New message'),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: isTeacher
                      ? 'Search parent or student'
                      : 'Search teacher',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                PageCard(
                  child: Column(
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                PageEmpty(
                  title: _contacts.isEmpty
                      ? 'No conversations yet'
                      : 'No matches',
                  message: _contacts.isEmpty
                      ? (isTeacher
                            ? 'Parents appear here once they are linked to students in your assigned classes.'
                            : 'Your child’s teachers appear here once your child is placed in a class.')
                      : 'Try another name.',
                )
              else
                for (final contact in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContactTile(
                      contact: contact,
                      onTap: () => _openConversation(contact),
                    ),
                  ),
              if (isTeacher) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnnouncementsView(),
                    ),
                  ),
                  child: const Text('View school notices'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final last = contact['last_message'] as Map?;
    final unread = (contact['unread'] as num?)?.toInt() ?? 0;
    final students = (contact['students'] as List? ?? []).join(', ');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread > 0 ? AppColors.blueBorder : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.softBlue,
                foregroundColor: AppColors.primary,
                child: Text(initialsOf(contact['name']?.toString() ?? '')),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact['role'] == 'teacher'
                          ? 'Teacher · $students'
                          : 'Parent of $students',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (last != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (last['from_me'] == true) ...[
                            MessageStatus(message: last),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              '${last['from_me'] == true ? 'You: ' : ''}${last['body']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (unread > 0) PageBadge('$unread new'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teacher compose: every parent in the assigned classes, or chosen parents.
class ComposeMessagePage extends StatefulWidget {
  final List<Map<String, dynamic>> parents;
  const ComposeMessagePage({super.key, required this.parents});

  @override
  State<ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<ComposeMessagePage> {
  bool _allParents = true;
  final Set<int> _selected = {};
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Write a message before sending.');
      return;
    }
    if (!_allParents && _selected.isEmpty) {
      setState(() => _error = 'Choose at least one parent.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/messages',
        data: _allParents
            ? {'all_parents': true, 'body': body}
            : {'recipient_ids': _selected.toList(), 'body': body},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message']?.toString() ?? 'Sent.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final data = e is DioException ? e.response?.data : null;
      setState(() {
        _sending = false;
        _error = data is Map
            ? data['message']?.toString() ?? 'Message could not be sent.'
            : 'Message could not be sent. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'New message'),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Send to',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          PageFilters(
            labels: const ['All parents', 'Choose parents'],
            selected: _allParents ? 'All parents' : 'Choose parents',
            onSelected: (v) => setState(() => _allParents = v == 'All parents'),
          ),
          const SizedBox(height: 16),
          if (_allParents)
            Text(
              'Every parent linked to your classes receives this message (${widget.parents.length}).',
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            )
          else
            PageCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final parent in widget.parents)
                    CheckboxListTile(
                      value: _selected.contains(parent['id']),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _selected.add(parent['id'] as int)
                            : _selected.remove(parent['id']),
                      ),
                      title: Text(parent['name']?.toString() ?? ''),
                      subtitle: Text(
                        'Parent of ${(parent['students'] as List? ?? []).join(', ')}',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _body,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(
              _sending
                  ? 'Sending…'
                  : _allParents
                  ? 'Send to all parents'
                  : 'Send to ${_selected.length} selected',
            ),
          ),
        ],
      ),
    ),
  );
}
