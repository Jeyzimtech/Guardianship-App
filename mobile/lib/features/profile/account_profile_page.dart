import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/session.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import '../common/student_avatar.dart';
import '../common/student_photo_page.dart';
import '../../core/legal.dart';
import '../legal/legal_document_page.dart';
import '../support/app_info_page.dart';
import '../support/help_center_page.dart';
import '../support/report_issue_page.dart';

class AccountProfilePage extends StatefulWidget {
  final Map<String, dynamic>? child;
  final bool parent;
  final bool showAppBar;
  const AccountProfilePage({
    super.key,
    this.child,
    this.parent = false,
    this.showAppBar = true,
  });
  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  final Map<int, String?> _photoOverrides = {};
  // A teacher's assigned classes, loaded from the server.
  List<Map<String, dynamic>>? _classes;
  bool _classesFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClasses());
  }

  Future<void> _loadClasses() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isTeacher || widget.parent) return;
    try {
      final response = await auth.apiClient.dio.get('/school-classes');
      if (!mounted) return;
      setState(() => _classes = [
        for (final c in response.data['school_classes'] as List? ?? []) Map<String, dynamic>.from(c),
      ]);
    } catch (_) {
      if (mounted) setState(() => _classesFailed = true);
    }
  }

  Widget _schoolRow(String title, String subtitle) => _detail(subtitle, title);

  @override
  void didUpdateWidget(covariant AccountProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child?['id'] != widget.child?['id'] ||
        oldWidget.child?['photo_url'] != widget.child?['photo_url']) {
      _photoOverrides.clear();
    }
  }

  Future<void> _editStudentPhoto(Map<String, dynamic> child) async {
    final id = child['id'];
    if (id is! int) return;
    final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => StudentPhotoPage(
      studentId: id, studentName: child['name']?.toString() ?? 'Your child',
      photoUrl: _photoOverrides.containsKey(id) ? _photoOverrides[id] : child['photo_url'] as String?)));
    if (!mounted || result == null) return;
    final url = result['photo_url'] as String?;
    setState(() => _photoOverrides[id] = url);
    context.read<StudentProvider>().updateStudentPhoto(id, url);
  }


  String _value(Map<String, dynamic>? user, String key) {
    final value = user?[key]?.toString().trim() ?? '';
    return value.isEmpty ? 'Not provided' : value;
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, AppSymbol icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(icon, size: 22, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  // Material keeps the ripple visible above the card's background.
  Widget _link(IconData icon, String title, Widget page, {String? subtitle}) => Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    ),
  );

  Future<void> _confirmExit({bool delete = false}) async {
    final teacher = context.read<AuthProvider>().isTeacher;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'Delete account?' : 'Log out?'),
        content: Text(
          delete
              ? teacher
                  ? 'This permanently deletes your account and personal details and cannot be undone. Attendance, reports and journal posts you created stay with the school as "Former teacher".'
                  : 'This permanently deletes your account, contact details and messages and cannot be undone. Your child\'s school records stay with the school.'
              : 'You can sign back in whenever you need to.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: delete ? AppColors.error : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(delete ? 'Delete account' : 'Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!delete) {
      await signOut(context);
      return;
    }
    final success = await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete your account. Please try again.'),
        ),
      );
      return;
    }
    context.read<StudentProvider>().clearData();
    resetToAuthGate(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?['name']?.toString().trim();
    final displayName = name == null || name.isEmpty ? 'Your profile' : name;
    final initials = displayName
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final parent = widget.parent || !auth.isTeacher;
    final selectedChild = widget.child ?? context.watch<StudentProvider>().selectedStudent;
    final selectedChildId = selectedChild?['id'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? supportingAppBar(context, 'My profile')
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeading(
              title: 'My profile',
              subtitle: 'Your details. Your connection to school.',
              symbol: AppSymbol.profile,
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    parent ? 'Parent / Guardian' : 'Teacher',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: auth.isLoading
                        ? null
                        : () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            backgroundColor: AppColors.surface,
                            builder: (_) => ProfileEditSheet(auth: auth),
                          ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.child != null)
              _section('Linked student', AppSymbol.student, [
                SizedBox(width: double.infinity, child: Column(children: [
                StudentAvatar(name: widget.child!['name']?.toString() ?? 'Student',
                  photoUrl: _photoOverrides.containsKey(widget.child!['id']) ? _photoOverrides[widget.child!['id']] : widget.child!['photo_url'] as String?, size: 76),
                const SizedBox(height: 14),
                Text(
                  widget.child!['name']?.toString() ?? 'Student',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                ])),
              ]),
            if (parent && selectedChildId is int)
              Padding(padding: const EdgeInsets.only(bottom: 16), child: OutlinedButton(onPressed: () => _editStudentPhoto(selectedChild!), child: const Text('Add / change student photo'))),
            _section('Contact details', AppSymbol.profile, [
              _detail('Phone number', _value(user, 'phone_number')),
              const Divider(height: 1),
              _detail('Email address', _value(user, 'email')),
              const Divider(height: 1),
              _detail('Home / postal address', _value(user, 'address')),
            ]),
            _section('Emergency contact', AppSymbol.message, [
              _detail('Contact name', _value(user, 'emergency_contact_name')),
              const Divider(height: 1),
              _detail('Contact phone', _value(user, 'emergency_contact_phone')),
            ]),
            _section('Preferences', AppSymbol.report, [
              _detail(
                'Preferred language',
                user?['preferred_language']?.toString() ?? 'English',
              ),
            ]),
            _section('Your school', AppSymbol.school, [
              if (parent)
                ...(() {
                  final children = context.watch<StudentProvider>().students;
                  return children.isEmpty
                      ? [const Text('No children are linked to your account yet.', style: TextStyle(color: AppColors.textMuted))]
                      : [
                          for (final c in children)
                            _schoolRow(
                              c['name']?.toString() ?? 'Student',
                              [c['school']?['name'], '${c['grade'] ?? ''} ${c['class_name'] ?? ''}'.trim()]
                                  .where((v) => v != null && v.toString().isNotEmpty)
                                  .join(' · '),
                            ),
                        ];
                })()
              else if (_classesFailed)
                const Text('Could not load your classes. Pull down on Home to retry.', style: TextStyle(color: AppColors.textMuted))
              else if (_classes == null)
                const Center(child: CircularProgressIndicator())
              else if (_classes!.isEmpty)
                const Text('Your school administrator has not assigned you a class yet.', style: TextStyle(color: AppColors.textMuted))
              else
                for (final c in _classes!)
                  _schoolRow('${c['grade'] ?? ''} · ${c['class_name'] ?? ''}', c['school']?['name']?.toString() ?? 'Assigned class'),
            ]),
            _section('Help & legal', AppSymbol.report, [
              _link(Icons.privacy_tip_outlined, 'Privacy policy', const LegalDocumentPage()),
              _link(Icons.description_outlined, 'Terms of use', const LegalDocumentPage(terms: true)),
              _link(Icons.help_outline, 'Help center', const HelpCenterPage(), subtitle: Legal.supportEmail),
              _link(Icons.bug_report_outlined, 'Report a technical issue', const ReportIssuePage()),
              _link(Icons.rate_review_outlined, 'Send feedback', const ReportIssuePage(category: 'feedback')),
              _link(Icons.info_outline, 'App info', const AppInfoPage()),
            ]),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _confirmExit(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => _confirmExit(delete: true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileEditSheet extends StatefulWidget {
  final AuthProvider auth;
  const ProfileEditSheet({super.key, required this.auth});
  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  static const _labels = {
    'name': 'Full name',
    'phone_number': 'Phone number',
    'email': 'Email address',
    'address': 'Home / postal address',
    'emergency_contact_name': 'Emergency contact name',
    'emergency_contact_phone': 'Emergency contact phone',
  };
  static const _languages = [
    'English',
    'Shona',
    'Ndebele',
    'French',
    'Portuguese',
  ];
  late String _language;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _fields = {
      for (final key in _labels.keys)
        key: TextEditingController(
          text: widget.auth.user?[key]?.toString() ?? '',
        ),
    };
    final language =
        widget.auth.user?['preferred_language']?.toString() ?? 'English';
    _language = _languages.contains(language) ? language : 'English';
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    bool success = false;
    try {
      success = await widget.auth.updateProfile(
        name: _fields['name']!.text.trim(),
        phone: _fields['phone_number']!.text.trim(),
        email: _fields['email']!.text.trim(),
        address: _fields['address']!.text.trim(),
        preferredLanguage: _language,
        emergencyContactName: _fields['emergency_contact_name']!.text.trim(),
        emergencyContactPhone: _fields['emergency_contact_phone']!.text.trim(),
      );
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } else {
      setState(() {
        _saving = false;
        _error = 'Could not save your details. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep your contact information up to date.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                for (final field in _fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: TextFormField(
                      controller: field.value,
                      enabled: !_saving,
                      maxLines: field.key == 'address' ? 2 : 1,
                      keyboardType: field.key.contains('phone')
                          ? TextInputType.phone
                          : field.key == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _labels[field.key],
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if ((field.key == 'name' ||
                                field.key == 'phone_number') &&
                            text.isEmpty) {
                          return '${_labels[field.key]} is required';
                        }
                        if (field.key == 'email' &&
                            text.isNotEmpty &&
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(text)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                  ),
                  items: _languages
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _language = value);
                        },
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
