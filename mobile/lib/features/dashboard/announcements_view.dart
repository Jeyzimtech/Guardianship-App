import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth_provider.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final key = _prefsKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await auth.apiClient.dio.get('/announcements');
      if (response.data['status'] != 'success') throw StateError('Load failed');
      if (!mounted) return;
      setState(() {
        _read = (prefs.getStringList(key) ?? []).toSet();
        _items = (response.data['announcements'] as List)
            .where(
              (a) =>
                  a['audience_role'] == 'all' ||
                  a['audience_role'] ==
                      (auth.isTeacher ? 'teacher' : 'guardian'),
            )
            .toList();
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
      (item['created_at'] ?? '').toString().split('T').first;
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
              const SizedBox(height: 24),
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
                          TextButton(
                            onPressed: () => _open(item),
                            child: const Text('Read notice'),
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
