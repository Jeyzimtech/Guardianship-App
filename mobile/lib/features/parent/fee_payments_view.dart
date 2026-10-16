import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';
import '../common/page_components.dart';

class FeePaymentsView extends StatefulWidget {
  final Map<String, dynamic>? child;
  const FeePaymentsView({super.key, this.child});
  @override
  State<FeePaymentsView> createState() => _FeePaymentsViewState();
}

class _FeePaymentsViewState extends State<FeePaymentsView> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _reference = TextEditingController();
  Map<String, dynamic>? _account;
  List<dynamic> _transactions = [];
  String _currency = 'USD', _method = 'EcoCash';
  String? _error;
  bool _loading = true, _saving = false;
  dynamic get _studentId =>
      widget.child?['id'] ??
      context.read<StudentProvider>().selectedStudent?['id'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_studentId == null) {
      setState(() {
        _loading = false;
        _error = 'Select a child to view school fees.';
      });
      return;
    }
    try {
      final response = await context.read<StudentProvider>().apiClient.dio.get(
        '/fees/$_studentId',
      );
      if (!mounted) return;
      setState(() {
        _account = Map<String, dynamic>.from(response.data['fee_account']);
        _transactions = response.data['transactions'] ?? [];
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load fees. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<StudentProvider>().apiClient.dio.post(
        '/fees/pay',
        data: {
          'student_id': _studentId,
          'amount': double.parse(_amount.text.trim()),
          'currency': _currency,
          'payment_method': _method,
          'reference': _reference.text.trim(),
        },
      );
      if (!mounted) return;
      _amount.clear();
      _reference.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reference submitted. Your school will verify receipt before updating the balance.',
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
              : 'Could not submit payment.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'School fees'),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'School fees',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
          if (_account != null) ...[
            PageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outstanding balance'),
                  const SizedBox(height: 8),
                  Text(
                    'USD ${_account!['balance_usd']}   ·   ZiG ${_account!['balance_zig']}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submit a payment reference',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pay using the details provided by your school, then submit the transaction reference here. This form does not charge your account. Your school verifies receipt before crediting your balance.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount paid'),
                    validator: (v) =>
                        (double.tryParse(v?.trim() ?? '') ?? 0) >= 1
                        ? null
                        : 'Enter an amount of at least 1',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: ['USD', 'ZiG']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                    ),
                    items: ['EcoCash', 'OneMoney', 'Card']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                  TextFormField(
                    controller: _reference,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Transaction reference',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter the transaction reference'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Submitting…' : 'Submit reference'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Payment history',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No payments recorded yet.'),
              ),
            for (final payment in _transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${payment['currency']} ${payment['amount']} · ${payment['status']}',
                ),
                subtitle: Text(
                  '${payment['reference'] ?? 'School payment'} · ${payment['created_at']?.toString().split('T').first ?? ''}',
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
