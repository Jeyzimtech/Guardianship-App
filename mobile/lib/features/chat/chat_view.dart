import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';
import '../../core/notification_provider.dart';
import 'message_status.dart';
import '../support/report_issue_page.dart';

/// One teacher-parent conversation, refreshed while open.
class ConversationView extends StatefulWidget {
  final Map<String, dynamic> contact;
  const ConversationView({super.key, required this.contact});

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poller;
  bool _fetching = false;
  final Set<int> _selected = {};
  bool _selecting = false;
  bool _deleting = false;
  bool _blocked = false;
  bool _messagingUnavailable = false;
  bool _changingBlock = false;

  void _report() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReportIssuePage(
        category: 'safety',
        contextDetails:
            'Conversation with user ${widget.contact['id']} (${widget.contact['name']}). Message IDs: ${_messages.map((m) => m['id']).join(', ')}. Describe the user or message you are reporting.',
      ),
    ),
  );

  Future<void> _toggleBlock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_blocked ? 'Unblock this user?' : 'Block this user?'),
        content: Text(
          _blocked
              ? 'Direct messaging can resume if the other user has not blocked you.'
              : 'Neither of you can send direct messages to the other while blocked. School-wide notices remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_blocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _changingBlock = true);
    try {
      final dio = context.read<AuthProvider>().apiClient.dio;
      final path = '/messages/block/${widget.contact['id']}';
      if (_blocked) {
        await dio.delete(path);
      } else {
        await dio.post(path);
      }
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update blocking. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingBlock = false);
    }
  }

  void _toggleSelection(int id) => setState(() {
    _selecting = true;
    if (!_selected.add(id)) _selected.remove(id);
  });

  Future<void> _deleteMessages({bool all = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          all
              ? 'Clear conversation?'
              : 'Delete ${_selected.length} selected messages?',
        ),
        content: const Text(
          'Messages will be removed from your view. The other person keeps their copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      // Wait for an in-flight refresh before changing the server's visible messages.
      while (_fetching) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;
      await context.read<AuthProvider>().apiClient.dio.delete(
        '/messages/with/${widget.contact['id']}',
        data: all ? {'all': true} : {'ids': _selected.toList()},
      );
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _selecting = false;
      });
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete messages. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    _messageController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        _fetching ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _fetching = true;
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/messages/with/${widget.contact['id']}',
      );
      if (!mounted) return;
      unawaited(
        context.read<NotificationProvider?>()?.refresh() ??
            Future<void>.value(),
      );
      final messages = (response.data['messages'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      final grew = messages.length != _messages.length;
      setState(() {
        _messages = messages;
        _blocked = response.data['blocked'] == true;
        _messagingUnavailable = response.data['messaging_unavailable'] == true;
        _error = null;
      });
      if (grew) _scrollToEnd();
    } catch (_) {
      if (mounted && _messages.isEmpty) {
        setState(() => _error = 'Unable to load this conversation.');
      }
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending || _messagingUnavailable) return;
    setState(() => _sending = true);
    try {
      await context.read<AuthProvider>().apiClient.dio.post(
        '/messages',
        data: {
          'recipient_ids': [widget.contact['id']],
          'body': text,
        },
      );
      _messageController.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      final data = e is DioException ? e.response?.data : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map
                ? data['message']?.toString() ?? 'Message could not be sent.'
                : 'Message could not be sent. Check your connection.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(dynamic value) {
    // The server stores UTC timestamps without a zone suffix.
    var raw = '${value ?? ''}'.replaceFirst(' ', 'T');
    if (raw.isNotEmpty && !raw.endsWith('Z') && !raw.contains('+')) raw += 'Z';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final students = (widget.contact['students'] as List? ?? []).join(', ');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_selecting) ...[
            IconButton(
              tooltip: 'Select all loaded messages',
              onPressed: _deleting
                  ? null
                  : () => setState(
                      () => _selected.addAll(
                        _messages.map((m) => m['id'] as int),
                      ),
                    ),
              icon: const Icon(Icons.select_all),
            ),
            IconButton(
              tooltip: 'Delete selected messages',
              onPressed: _deleting || _selected.isEmpty
                  ? null
                  : () => _deleteMessages(),
              icon: const Icon(Icons.delete_outline),
            ),
            IconButton(
              tooltip: 'Cancel selection',
              onPressed: _deleting
                  ? null
                  : () => setState(() {
                      _selecting = false;
                      _selected.clear();
                    }),
              icon: const Icon(Icons.close),
            ),
          ] else
            PopupMenuButton<String>(
              enabled: !_deleting && !_changingBlock,
              onSelected: (value) {
                if (value == 'report') {
                  _report();
                  return;
                }
                if (value == 'block') {
                  _toggleBlock();
                  return;
                }
                if (value == 'clear') {
                  _deleteMessages(all: true);
                } else {
                  setState(() => _selecting = true);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report content or user'),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Text(_blocked ? 'Unblock user' : 'Block user'),
                ),
                PopupMenuItem(value: 'select', child: Text('Select messages')),
                PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear conversation'),
                ),
              ],
            ),
        ],
        title: _selecting
            ? Text('${_selected.length} selected')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact['name']?.toString() ?? 'Conversation',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (students.isNotEmpty)
                    Text(
                      widget.contact['role'] == 'teacher'
                          ? 'Teacher · $students'
                          : 'Parent of $students',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No messages yet. Write the first one below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['from_me'] == true;
                      return GestureDetector(
                        onLongPress: _deleting
                            ? null
                            : () => _toggleSelection(msg['id'] as int),
                        onTap: !_selecting || _deleting
                            ? null
                            : () => _toggleSelection(msg['id'] as int),
                        child: Row(
                          children: [
                            if (_selecting)
                              Checkbox(
                                value: _selected.contains(msg['id']),
                                onChanged: _deleting
                                    ? null
                                    : (_) => _toggleSelection(msg['id'] as int),
                              ),
                            Expanded(
                              child: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isMe
                                          ? AppColors.primary
                                          : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['body']?.toString() ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _time(msg['created_at']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isMe
                                                  ? Colors.white70
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 6),
                                            MessageStatus(
                                              message: msg,
                                              onDark: true,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_messagingUnavailable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _blocked
                            ? 'You blocked this user. Use the menu to unblock.'
                            : 'Messaging is unavailable for this contact.',
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_messagingUnavailable && !_changingBlock,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Type your message…',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed:
                            _sending || _messagingUnavailable || _changingBlock
                            ? null
                            : _send,
                        child: Text(_sending ? 'Sending…' : 'Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
