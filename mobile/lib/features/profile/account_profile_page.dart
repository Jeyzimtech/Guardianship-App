import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import '../school_management/school_management_screen.dart';
import '../teacher_management/teacher_management_screen.dart';

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
  bool _notificationsEnabled = true;

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

  Future<void> _confirmExit({bool delete = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'Delete account?' : 'Log out?'),
        content: Text(
          delete
              ? 'This permanently deletes your account and cannot be undone.'
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
    final auth = context.read<AuthProvider>();
    final students = context.read<StudentProvider>();
    if (delete) {
      final success = await auth.deleteAccount();
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete your account. Please try again.'),
          ),
        );
        return;
      }
    } else {
      await auth.logout();
    }
    students.clearData();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  widget.child!['name']?.toString() ?? 'Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [widget.child!['class'], widget.child!['school']]
                      .where((v) => v != null && v.toString().isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ]),
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
              if (parent) ...[
                const Divider(height: 1),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Attendance and school announcements',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                ),
              ],
            ]),
            _section('Your school', AppSymbol.school, [
              if (!parent)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherManagementScreen(),
                    ),
                  ),
                  child: const Text('Class & teacher roster'),
                ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SchoolManagementScreen(),
                  ),
                ),
                child: const Text('School & class information'),
              ),
            ]),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _confirmExit(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out'),
            ),
            if (widget.parent) ...[
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
