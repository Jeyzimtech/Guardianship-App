from pathlib import Path
r=Path('mobile/lib/features/parent')
(r/'child_information_page.dart').write_text('''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import '../common/student_avatar.dart';
class ChildInformationPage extends StatelessWidget {
  const ChildInformationPage({super.key});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<StudentProvider>().selectedStudent ?? {};
    return Scaffold(appBar: supportingAppBar(context, 'Child information'), body: ListView(padding: const EdgeInsets.all(24), children: [
      const PageHeading(title: 'Your child, at a glance.', subtitle: 'Details held by your school. Contact the school to request a correction.', symbol: AppSymbol.profile),
      PageCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StudentAvatar(name: child['name']?.toString() ?? 'Your child', photoUrl: child['photo_url'] as String?, size: 72),
        const SizedBox(height: 20),
        for (final row in [
          ('Name', child['name']), ('School', child['school'] is Map ? child['school']['name'] : child['school']),
          ('Grade', child['grade']), ('Class', child['class_name']), ('Date of birth', child['dob']?.toString().split('T').first),
        ]) ListTile(contentPadding: EdgeInsets.zero, title: Text(row.$1), subtitle: Text(row.$2?.toString() ?? 'Not provided')),
      ])),
    ]));
  }
}
''')
(r/'activity_participation_page.dart').write_text('''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
class ActivityParticipationPage extends StatefulWidget {
  const ActivityParticipationPage({super.key});
  @override
  State<ActivityParticipationPage> createState() => _ActivityParticipationPageState();
}
class _ActivityParticipationPageState extends State<ActivityParticipationPage> {
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    final id = provider.selectedStudent?['id'];
    setState(() { _loading = true; _error = null; });
    try {
      final response = await provider.apiClient.dio.get('/activities/student/$id');
      if (mounted) setState(() => _activities = (response.data['activities'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) { if (mounted) setState(() => _error = 'Could not load activities. Pull down to try again.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: supportingAppBar(context, 'Tasks & activities'), body: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
    const PageHeading(title: 'Beyond the classroom.', subtitle: 'Sports, extra lessons and tasks recorded by your school.', symbol: AppSymbol.attendance),
    if (_loading) const Center(child: CircularProgressIndicator())
    else if (_error != null) Text(_error!)
    else if (_activities.isEmpty) const PageEmpty(title: 'No activities recorded yet', message: 'Participation added by the school will appear here.')
    else for (final item in _activities) Padding(padding: const EdgeInsets.only(bottom: 16), child: PageCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(item['title']?.toString() ?? 'Activity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8), Text(item['activity_date']?.toString().split('T').first ?? ''),
      if ((item['description']?.toString() ?? '').isNotEmpty) ...[const SizedBox(height: 12), Text(item['description'])],
      const SizedBox(height: 12), PageBadge(switch (item['status']) {'present' => 'Took part', 'late' => 'Took part · Late', 'absent' => 'Did not attend', _ => 'On the register'}),
    ]))),
  ])));
}
''')
(r/'payment_proof_page.dart').write_text('''import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_icon.dart';
import '../../core/app_colors.dart';
import '../common/page_components.dart';
class PaymentProofPage extends StatefulWidget {
  const PaymentProofPage({super.key});
  @override
  State<PaymentProofPage> createState() => _PaymentProofPageState();
}
class _PaymentProofPageState extends State<PaymentProofPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String _currency = 'USD';
  String _method = 'EcoCash';
  PlatformFile? _file;
  bool _loading = true, _sending = false;
  String? _error;
  Map<String, dynamic> _account = {};
  List<dynamic> _transactions = [];
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  @override
  void dispose() { _amount.dispose(); _reference.dispose(); super.dispose(); }
  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    try {
      final response = await provider.apiClient.dio.get('/fees/${provider.selectedStudent?['id']}');
      if (mounted) setState(() { _account = Map<String, dynamic>.from(response.data['fee_account'] ?? {}); _transactions = response.data['transactions'] ?? []; _error = null; });
    } catch (_) { if (mounted) setState(() => _error = 'Could not load payments. Please try again.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
    if (!mounted || result == null) return;
    if (result.files.single.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a file smaller than 5 MB.'))); return;
    }
    setState(() => _file = result.files.single);
  }
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      final provider = context.read<StudentProvider>();
      final data = <String, dynamic>{'student_id': provider.selectedStudent?['id'], 'amount': _amount.text.trim(), 'reference': _reference.text.trim(), 'currency': _currency, 'payment_method': _method};
      if (_file != null) data['proof'] = MultipartFile.fromBytes(_file!.bytes!, filename: _file!.name);
      await provider.apiClient.dio.post('/fees/pay', data: FormData.fromMap(data));
      if (!mounted) return;
      _amount.clear(); _reference.clear(); setState(() => _file = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proof submitted. Your school will verify the payment.')));
      await _load();
    } on DioException catch (e) {
      if (mounted) setState(() => _error = e.response?.data is Map ? e.response!.data['message']?.toString() ?? 'Could not submit payment.' : 'Could not submit payment. Please try again.');
    } catch (_) { if (mounted) setState(() => _error = 'Could not submit payment. Please try again.'); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: supportingAppBar(context, 'Proof of payment'), body: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
    const PageHeading(title: 'Payment, clearly recorded.', subtitle: 'Send a school fee payment reference and receipt for verification. This is separate from your app subscription.', symbol: AppSymbol.report),
    if (_loading) const Center(child: CircularProgressIndicator()) else ...[
      PageCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Outstanding school fees'), const SizedBox(height: 8), Text('USD ${_account['balance_usd'] ?? 0}  ·  ZiG ${_account['balance_zig'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))])),
      const SizedBox(height: 20),
      PageCard(child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Submit payment proof', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 16),
        TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount paid'), validator: (v) => (double.tryParse(v ?? '') ?? 0) < 1 ? 'Enter an amount of at least 1' : null), const SizedBox(height: 14),
        DropdownButtonFormField<String>(initialValue: _currency, decoration: const InputDecoration(labelText: 'Currency'), items: ['USD','ZiG'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _currency = v!)), const SizedBox(height: 14),
        DropdownButtonFormField<String>(initialValue: _method, decoration: const InputDecoration(labelText: 'Payment method'), items: ['EcoCash','OneMoney','Card'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _method = v!)), const SizedBox(height: 14),
        TextFormField(controller: _reference, maxLength: 100, decoration: const InputDecoration(labelText: 'Payment reference'), validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the payment reference' : null),
        OutlinedButton.icon(onPressed: _sending ? null : _pick, icon: const Icon(Icons.attach_file), label: Text(_file?.name ?? 'Attach receipt (optional)')),
        const Text('JPG, PNG or PDF · up to 5 MB', style: TextStyle(color: AppColors.textMuted)), const SizedBox(height: 16),
        FilledButton(onPressed: _sending ? null : _submit, child: Text(_sending ? 'Submitting…' : 'Submit for verification')),
      ]))),
      const SizedBox(height: 24), const Text('Payment history', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
      if (_transactions.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No payments submitted yet.')),
      for (final payment in _transactions) ListTile(contentPadding: EdgeInsets.zero, title: Text('${payment['currency']} ${payment['amount']}'), subtitle: Text('${payment['reference'] ?? ''} · ${payment['created_at']?.toString().split('T').first ?? ''}'), trailing: Text(payment['status'] == 'completed' ? 'Verified' : 'Pending')),
    ],
    if (_error != null) ...[Text(_error!, style: const TextStyle(color: AppColors.error)), TextButton(onPressed: _load, child: const Text('Try again'))],
  ])));
}
''')
p=r/'parent_dashboard_view.dart';s=p.read_text();s=s.replace("import 'uniform_marketplace_view.dart';", "import 'uniform_marketplace_view.dart';\nimport 'child_information_page.dart';\nimport 'payment_proof_page.dart';\nimport 'activity_participation_page.dart';\nimport 'subscription_page.dart';\nimport 'guardian_profile_view.dart';\nimport '../common/documents_view.dart';")
needle="            const SizedBox(height: 28),\n            EditorialFeature("
s=s.replace(needle, '''            const SizedBox(height: 24),
            const Text('Your school essentials', style: Editorial.section),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final action in <(String, IconData, Widget)>[
                ('Child information', Icons.person_outline, const ChildInformationPage()),
                ('Proof of payment', Icons.receipt_long_outlined, const PaymentProofPage()),
                ('School documents', Icons.folder_open_outlined, const DocumentsView()),
                ('Profile', Icons.manage_accounts_outlined, GuardianProfileView(child: child)),
              ]) SizedBox(width: (MediaQuery.sizeOf(context).width - 58) / 2,
                child: OutlinedButton(onPressed: hasStudents || action.$1 == 'Profile' ? () => _open(action.$3) : null,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), alignment: Alignment.centerLeft),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(action.$2), const SizedBox(height: 12), Text(action.$1)]))),
            ]),
            const SizedBox(height: 28),
            EditorialFeature(''')
s=s.replace("            const Text('Learning & progress', style: Editorial.section),", "            const Text('Learning & progress', style: Editorial.section),")
s=s.replace("            EditorialLink(\n              title: 'Homework',", "            EditorialLink(title: 'Tasks & activities', subtitle: 'Sports, extra lessons and participation', onTap: () => _open(const ActivityParticipationPage())),\n            EditorialLink(\n              title: 'Homework',")
s=s.replace("            const Text('School essentials', style: Editorial.section),", "            const Text('School essentials', style: Editorial.section),\n            EditorialLink(title: 'Subscription', subtitle: 'Information and activation support', onTap: () => _open(const SubscriptionPage())),")
p.write_text(s)
# Every new notice must explain message retention before a conversation is sent.
p=Path('mobile/lib/features/parent/messaging_view.dart');s=p.read_text();needle="'Teacher conversations'";s=s.replace("'Keep in touch", "'Messages expire after 7 days. Keep in touch");p.write_text(s)
