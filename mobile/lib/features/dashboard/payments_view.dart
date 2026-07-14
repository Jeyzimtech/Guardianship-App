import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _feeAccount;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFeeDetails();
  }

  Future<void> _fetchFeeDetails() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final selectedStudent = studentProvider.selectedStudent;
    if (selectedStudent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get('/fees/${selectedStudent['id']}');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _feeAccount = response.data['fee_account'];
          _transactions = response.data['transactions'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load fee details.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showPaymentBottomSheet() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final selectedStudent = studentProvider.selectedStudent;
    if (selectedStudent == null) return;

    double balanceUsd = double.parse(_feeAccount?['balance_usd']?.toString() ?? '0.0');
    double balanceZig = double.parse(_feeAccount?['balance_zig']?.toString() ?? '0.0');

    if (balanceUsd <= 0 && balanceZig <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fees are cleared! No outstanding balance.')),
      );
      return;
    }

    const oldDarkBlue = Color(0xFF002D62);
    const cardBgColor = Color(0xFFFFFDF0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        side: BorderSide(color: oldDarkBlue, width: 1.5),
      ),
      builder: (context) {
        return PaymentForm(
          studentId: selectedStudent['id'],
          balanceUsd: balanceUsd,
          balanceZig: balanceZig,
          onPaymentCompleted: () {
            Navigator.pop(context);
            _fetchFeeDetails();
            studentProvider.fetchDashboard(selectedStudent['id']);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlue = Color(0xFF002D62);

    return Scaffold(
      backgroundColor: vanillaColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: oldDarkBlue))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchFeeDetails,
                  color: oldDarkBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceHeader(vanillaColor, oldDarkBlue),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: oldDarkBlue),
                            ),
                            Icon(Icons.history_rounded, color: oldDarkBlue.withValues(alpha: 0.5), size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_transactions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32.0),
                            child: Center(
                              child: Text(
                                'No payment transactions recorded yet.',
                                style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              final isCompleted = tx['status'] == 'completed';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: oldDarkBlue,
                                    child: Icon(Icons.arrow_upward_rounded, color: vanillaColor, size: 20),
                                  ),
                                  title: Text(
                                    'Fee Payment via ${tx['payment_method']}',
                                    style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    tx['created_at']?.split('T')[0] ?? '',
                                    style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${tx['currency'] == 'USD' ? '\$' : ''}${tx['amount']} ${tx['currency'] == 'ZiG' ? 'ZiG' : ''}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isCompleted ? 'Completed' : 'Pending',
                                        style: TextStyle(
                                          color: isCompleted ? Colors.green : Colors.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceHeader(Color vanillaColor, Color oldDarkBlue) {
    double balanceUsd = double.parse(_feeAccount?['balance_usd']?.toString() ?? '0.0');
    double balanceZig = double.parse(_feeAccount?['balance_zig']?.toString() ?? '0.0');
    bool hasFees = balanceUsd > 0 || balanceZig > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: oldDarkBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: oldDarkBlue.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OUTSTANDING BALANCE', style: TextStyle(color: oldDarkBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFees ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: hasFees ? Colors.red : Colors.green, width: 1.5),
                ),
                child: Text(
                  hasFees ? 'PAYMENT DUE' : 'CLEARED',
                  style: TextStyle(color: hasFees ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$$balanceUsd', style: TextStyle(color: oldDarkBlue, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('USD Balance', style: TextStyle(color: oldDarkBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${balanceZig.toInt()} ZiG', style: TextStyle(color: oldDarkBlue, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('ZiG Balance', style: TextStyle(color: oldDarkBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasFees)
            ElevatedButton.icon(
              onPressed: _showPaymentBottomSheet,
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: const Text('Pay Outstanding Fees', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: oldDarkBlue,
                foregroundColor: vanillaColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Thank you! Your fee account is up-to-date.', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            )
        ],
      ),
    );
  }
}

class PaymentForm extends StatefulWidget {
  final int studentId;
  final double balanceUsd;
  final double balanceZig;
  final VoidCallback onPaymentCompleted;

  const PaymentForm({
    super.key,
    required this.studentId,
    required this.balanceUsd,
    required this.balanceZig,
    required this.onPaymentCompleted,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedMethod = 'EcoCash';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.balanceUsd > 0
        ? widget.balanceUsd.toString()
        : widget.balanceZig.toString();
    _selectedCurrency = widget.balanceUsd > 0 ? 'USD' : 'ZiG';
  }

  void _submitPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final provider = Provider.of<StudentProvider>(context, listen: false);
    final success = await provider.payFees(
      studentId: widget.studentId,
      amount: amount,
      currency: _selectedCurrency,
      paymentMethod: _selectedMethod,
    );

    setState(() {
      _isProcessing = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment processed successfully!')),
      );
      widget.onPaymentCompleted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process payment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlue = Color(0xFF002D62);
    
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Make School Payment', style: TextStyle(color: oldDarkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: oldDarkBlue), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('USD')),
                  selected: _selectedCurrency == 'USD',
                  selectedColor: oldDarkBlue,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: _selectedCurrency == 'USD' ? vanillaColor : oldDarkBlue, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: oldDarkBlue)),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCurrency = 'USD';
                        _amountController.text = widget.balanceUsd.toString();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('ZiG')),
                  selected: _selectedCurrency == 'ZiG',
                  selectedColor: oldDarkBlue,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: _selectedCurrency == 'ZiG' ? vanillaColor : oldDarkBlue, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: oldDarkBlue)),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCurrency = 'ZiG';
                        _amountController.text = widget.balanceZig.toString();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              labelStyle: const TextStyle(color: oldDarkBlue),
              prefixIcon: const Icon(
                Icons.attach_money_rounded,
                color: oldDarkBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Select Payment Method', style: TextStyle(color: oldDarkBlue, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            dropdownColor: const Color(0xFFFFFDF0),
            style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payment_rounded, color: oldDarkBlue),
            ),
            items: ['EcoCash', 'OneMoney', 'Card'].map((method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedMethod = val);
              }
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isProcessing ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: oldDarkBlue,
              foregroundColor: vanillaColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: vanillaColor, strokeWidth: 2.5),
                  )
                : Text(
                    'Pay Amount (${_selectedCurrency == 'USD' ? '\$' : ''}${_amountController.text} ${_selectedCurrency == 'ZiG' ? 'ZiG' : ''})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}
