import '../common/report_content_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth_provider.dart';
import '../../core/notification_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class AnnouncementsView extends StatefulWidget {
  final bool notifications;
  const AnnouncementsView({super.key, this.notifications = false});
  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  List<dynamic> _items = [];
  Set<String> _read = {};
  final Set<String> _selected = {};
  bool _selecting = false;
  bool _deleting = false;

  void _toggleSelection(dynamic item) => setState(() {
    _selecting = true;
    if (!_selected.add(_id(item))) _selected.remove(_id(item));
  });

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || _loading || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selected.length} selected notifications?'),
        content: const Text(
          'These updates will be removed from your view. Other users keep their copies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = Set<String>.of(_selected);
    setState(() => _deleting = true);
    try {
      final dio = context.read<AuthProvider>().apiClient.dio;
      final list = ids.toList();
      for (var start = 0; start < list.length; start += 1000) {
        final batch = list.skip(start).take(1000).toList();
        await dio.delete(
          '/mobile-notifications',
          data: {
            'items': batch
                .map(
                  (id) => {
                    'category': id.startsWith('sos_') ? 'sos' : 'notices',
                    'id': int.parse(
                      id.startsWith('sos_') ? id.substring(4) : id,
                    ),
                  },
                )
                .toList(),
          },
        );
        if (!mounted) return;
        setState(() {
          _items.removeWhere((item) => batch.contains(_id(item)));
          _selected.removeAll(batch);
        });
      }
      if (!mounted) return;
      setState(() => _selecting = false);
      await context.read<NotificationProvider?>()?.refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete all selected notifications. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  bool _loading = true;
  String? _error;
  String _filter = 'All';
  String _query = '';
  final _search = TextEditingController();
  String get _prefsKey =>
      'notice_reads_${context.read<AuthProvider>().user?['id'] ?? context.read<AuthProvider>().user?['email'] ?? 'local'}';
  String _id(dynamic item) =>
      '${item['id'] ?? '${item['created_at']}_${item['title']}'}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_deleting) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final key = _prefsKey;
    try {
      final updates = context.read<NotificationProvider?>();
      await updates?.refresh();
      final prefs = await SharedPreferences.getInstance();
      await updates?.markRead(
        'notices',
        (prefs.getStringList(key) ?? []).map(int.tryParse).whereType<int>(),
      );
      final response = await auth.apiClient.dio.get('/announcements');
      if (response.data['status'] != 'success') throw StateError('Load failed');
      // Emergency SOS alerts stay in a parent's notifications after the alarm.
      var sos = <dynamic>[];
      if (auth.isGuardian) {
        try {
          final alerts = await auth.apiClient.dio.get('/sos/history');
          sos = [
            for (final a in alerts.data['alerts'] as List? ?? [])
              {
                'id': 'sos_${a['id']}',
                'category': 'Urgent',
                'title': 'Emergency SOS',
                'content':
                    '${a['message']}\n\nFrom ${a['teacher_name']}. Contact your school immediately.',
                'created_at': a['created_at'],
                'audience_role': 'guardian',
              },
          ];
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _read = {...?updates?.noticeReads, ...(prefs.getStringList(key) ?? [])};
        _items = [
          ...sos,
          ...(response.data['announcements'] as List).where(
            (a) =>
                a['audience_role'] == 'all' ||
                a['audience_role'] == (auth.isTeacher ? 'teacher' : 'guardian'),
          ),
        ]..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
        _selected.retainAll(_items.map(_id));
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to load school updates. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Iterable<dynamic> items) async {
    final updates = context.read<NotificationProvider?>();
    await updates?.markRead(
      'notices',
      items.map((item) => int.tryParse('${item['id']}')).whereType<int>(),
    );
    if (!mounted) return;
    final key = _prefsKey;
    setState(() => _read.addAll(items.map(_id)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _read.toList());
  }

  void _open(dynamic item) {
    _markRead([item]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageBadge(item['category'] ?? 'General'),
                const SizedBox(height: 18),
                Text(
                  item['title'] ?? 'School notice',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _date(item),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Text(
                  item['content'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.7),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _date(dynamic item) =>
      (item['created_at'] ?? '').toString().split(RegExp('[T ]')).first;

  // SOS rows use "Y-m-d H:i:s" while notices use ISO 8601.
  static String _sortKey(dynamic item) =>
      '${item['created_at'] ?? ''}'.replaceFirst('T', ' ');
  @override
  Widget build(BuildContext context) {
    final unread = _items.where((a) => !_read.contains(_id(a))).length;
    final filtered = _items
        .where(
          (a) =>
              (_filter == 'All' ||
                  (_filter == 'Unread'
                      ? !_read.contains(_id(a))
                      : (a['category'] ?? 'General') == _filter)) &&
              '${a['title']} ${a['content']}'.toLowerCase().contains(_query),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(
        context,
        widget.notifications ? 'Notifications' : 'Notices',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              PageHeading(
                title: widget.notifications
                    ? 'Notifications'
                    : 'School notices',
                subtitle: widget.notifications
                    ? 'Your school updates, all in one place.'
                    : 'Stay connected to what is happening at school.',
                symbol: AppSymbol.message,
              ),
              PageCard(
                color: AppColors.softBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notifications
                          ? '$unread unread updates'
                          : 'The school noticeboard',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Announcements, important dates and messages for your school community.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (unread > 0)
                      TextButton(
                        onPressed: () => _markRead(_items),
                        child: const Text('Mark all as read'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_loading && _items.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!_selecting)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _selecting = true),
                        icon: const Icon(Icons.checklist),
                        label: const Text('Select notifications'),
                      )
                    else ...[
                      Text('${_selected.length} selected'),
                      TextButton(
                        onPressed: _deleting
                            ? null
                            : () => setState(
                                () => _selected.addAll(filtered.map(_id)),
                              ),
                        child: const Text('Select all shown'),
                      ),
                      FilledButton.icon(
                        onPressed: _deleting || _selected.isEmpty
                            ? null
                            : _deleteSelected,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          _deleting ? 'Deleting...' : 'Delete selected',
                        ),
                      ),
                      TextButton(
                        onPressed: _deleting
                            ? null
                            : () => setState(() {
                                _selecting = false;
                                _selected.clear();
                              }),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search school updates',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              PageFilters(
                labels: const [
                  'All',
                  'Unread',
                  'Urgent',
                  'School Events',
                  'General',
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 24),
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
                const PageEmpty(
                  title: 'You’re all caught up',
                  message:
                      'No updates match this view. Try another filter or pull down to refresh.',
                )
              else ...[
                Text(
                  '${filtered.length} school updates',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                for (final item in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selecting)
                            Material(
                              color: Colors.transparent,
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Select notification'),
                                value: _selected.contains(_id(item)),
                                onChanged: _deleting
                                    ? null
                                    : (_) => _toggleSelection(item),
                              ),
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              PageBadge(
                                item['category'] ?? 'General',
                                color: item['category'] == 'Urgent'
                                    ? const Color(0xFFB42318)
                                    : AppColors.primary,
                              ),
                              if (!_read.contains(_id(item)))
                                const PageBadge('Unread'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['title'] ?? 'School notice',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['content'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _date(item),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          ReportContentButton(
                            details:
                                'School notice ${_id(item)}: ${item['title'] ?? ''}',
                          ),
                          TextButton(
                            onPressed: _deleting
                                ? null
                                : () => _selecting
                                      ? _toggleSelection(item)
                                      : _open(item),
                            child: Text(
                              _selecting
                                  ? (_selected.contains(_id(item))
                                        ? 'Deselect'
                                        : 'Select')
                                  : 'Read notice',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
