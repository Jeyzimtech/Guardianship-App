import 'package:dio/dio.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    try {
      final response = await provider.apiClient.dio.get(
        '/fees/${provider.selectedStudent?['id']}',
      );
      if (mounted) {
        setState(() {
          _account = Map<String, dynamic>.from(
            response.data['fee_account'] ?? {},
          );
          _transactions = response.data['transactions'] ?? [];
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load payments. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || file == null) return;
    final length = await file.length();
    if (!mounted) return;
    if (length == null || length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a file smaller than 5 MB.')),
      );
      return;
    }
    setState(() => _file = file);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final provider = context.read<StudentProvider>();
      final data = <String, dynamic>{
        'student_id': provider.selectedStudent?['id'],
        'amount': _amount.text.trim(),
        'reference': _reference.text.trim(),
        'currency': _currency,
        'payment_method': _method,
      };
      if (_file != null) {
        data['proof'] = MultipartFile.fromBytes(
          await _file!.readAsBytes(),
          filename: _file!.name,
        );
      }
      await provider.apiClient.dio.post(
        '/fees/pay',
        data: FormData.fromMap(data),
      );
      if (!mounted) return;
      _amount.clear();
      _reference.clear();
      setState(() => _file = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proof submitted. Your school will verify the payment.',
          ),
        ),
      );
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.response?.data is Map
              ? e.response!.data['message']?.toString() ??
                    'Could not submit payment.'
              : 'Could not submit payment. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not submit payment. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: supportingAppBar(context, 'Proof of payment'),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            title: 'Payment, clearly recorded.',
            subtitle:
                'Send a school fee payment reference and receipt for verification. This is separate from your app subscription.',
            symbol: AppSymbol.report,
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            PageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outstanding school fees'),
                  const SizedBox(height: 8),
                  Text(
                    'USD ${_account['balance_usd'] ?? 0}  ·  ZiG ${_account['balance_zig'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PageCard(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit payment proof',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount paid',
                      ),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) < 1
                          ? 'Enter an amount of at least 1'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: ['USD', 'ZiG']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                      ),
                      items: ['EcoCash', 'OneMoney', 'Card']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _reference,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Payment reference',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter the payment reference'
                          : null,
                    ),
                    OutlinedButton.icon(
                      onPressed: _sending ? null : _pick,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_file?.name ?? 'Attach receipt (optional)'),
                    ),
                    const Text(
                      'JPG, PNG or PDF · up to 5 MB',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _sending ? null : _submit,
                      child: Text(
                        _sending ? 'Submitting…' : 'Submit for verification',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment history',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No payments submitted yet.'),
              ),
            for (final payment in _transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${payment['currency']} ${payment['amount']}'),
                subtitle: Text(
                  '${payment['reference'] ?? ''} · ${payment['created_at']?.toString().split('T').first ?? ''}',
                ),
                trailing: Text(
                  payment['status'] == 'completed' ? 'Verified' : 'Pending',
                ),
              ),
          ],
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}
