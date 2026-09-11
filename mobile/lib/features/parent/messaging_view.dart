import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class MessagingView extends StatefulWidget {
  const MessagingView({super.key});

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Mrs. Grace Mupfu...',
      'initials': 'GM',
      'color': AppColors.primary,
      'preview': 'Thank you for the update, Mr. Che...',
      'time': 'Mon 10:32',
      'unread': 2,
    },
    {
      'name': 'Mr. Sithole — School Accoun...',
      'initials': 'MS',
      'color': AppColors.primaryDark,
      'preview': 'Thank you for the school update.',
      'time': 'Fri 14:15',
      'unread': 0,
    },
    {
      'name': 'Mrs. Dube — Deput...',
      'initials': 'AD',
      'color': AppColors.primaryLight,
      'preview': 'Please confirm your attendance f...',
      'time': 'Thu 09:00',
      'unread': 1,
    },
    {
      'name': 'Edu+Conect Support',
      'initials': 'ES',
      'color': AppColors.primaryAccent,
      'preview': 'Welcome to the platform! Let us know if you ...',
      'time': '22 Oct',
      'unread': 0,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations
        .where(
          (c) =>
              c['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c['preview'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── SEARCH BAR ──
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.softBlue,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.blueBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.blueBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── CONVERSATION LIST ──
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations found.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (ctx, i) {
                      final c = _filtered[i];
                      final hasUnread = (c['unread'] as int) > 0;

                      return InkWell(
                        onTap: () => _openConversation(context, c),
                        child: Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: c['color'] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    c['initials'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name + Preview
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      c['preview'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: hasUnread
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                        fontWeight: hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Time + Badge
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    c['time'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hasUnread
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (hasUnread)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${c['unread']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 20, height: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewMessageSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        elevation: 2,
      ),
    );
  }

  void _openConversation(BuildContext context, Map<String, dynamic> conv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ConversationPage(conv: conv)),
    );
  }

  void _showNewMessageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                labelText: 'To (Teacher / School Staff)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CONVERSATION DETAIL PAGE ──
class _ConversationPage extends StatefulWidget {
  final Map<String, dynamic> conv;
  const _ConversationPage({required this.conv});

  @override
  State<_ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<_ConversationPage> {
  final _textController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text':
          'Good morning! Alice performed excellently in today\'s Mathematics session.',
      'time': '09:15',
    },
    {
      'isMe': true,
      'text': 'Thank you for the update, Mr. Che...',
      'time': '10:32',
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'isMe': true, 'text': text, 'time': 'Now'});
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.conv['initials'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.conv['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMe ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white60 : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
