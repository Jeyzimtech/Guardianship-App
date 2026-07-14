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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PaymentForm(
          studentId: selectedStudent['id'],
          balanceUsd: balanceUsd,
          balanceZig: balanceZig,
          onPaymentCompleted: () {
            Navigator.pop(context);
            _fetchFeeDetails();
            // Refresh student provider's dashboard data
            studentProvider.fetchDashboard(selectedStudent['id']);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _fetchFeeDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fee Balance Header Card
                        _buildBalanceHeader(),
                        const SizedBox(height: 24),
                        
                        // Transaction History Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Icon(Icons.history, color: Colors.white.withOpacity(0.4), size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_transactions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32.0),
                            child: Center(
                              child: Text(
                                'No payment transactions recorded yet.',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                                color: Colors.white.withOpacity(0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 20),
                                  ),
                                  title: Text(
                                    'Fee Payment via ${tx['payment_method']}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    tx['created_at']?.split('T')[0] ?? '',
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${tx['currency'] == 'USD' ? '\$' : ''}${tx['amount']} ${tx['currency'] == 'ZiG' ? 'ZiG' : ''}',
                                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isCompleted ? 'Completed' : 'Pending',
                                        style: TextStyle(
                                          color: isCompleted ? Colors.tealAccent.withOpacity(0.7) : Colors.amberAccent,
                                          fontSize: 10,
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

  Widget _buildBalanceHeader() {
    double balanceUsd = double.parse(_feeAccount?['balance_usd']?.toString() ?? '0.0');
    double balanceZig = double.parse(_feeAccount?['balance_zig']?.toString() ?? '0.0');
    bool hasFees = balanceUsd > 0 || balanceZig > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasFees
              ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)] // Deep Reds
              : [const Color(0xFF065F46), const Color(0xFF064E3B)], // Deep Greens
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasFees ? Colors.red : Colors.green).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OUTSTANDING BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasFees ? 'PAYMENT DUE' : 'CLEARED',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  Text('\$$balanceUsd', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('USD Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${balanceZig.toInt()} ZiG', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('ZiG Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[900],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Thank you! Your fee account is up-to-date.', style: TextStyle(color: Colors.white, fontSize: 14)),
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
    // Default input amount to outstanding balance
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
              const Text('Make School Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          // Currency Selector Card
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('USD')),
                  selected: _selectedCurrency == 'USD',
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(color: _selectedCurrency == 'USD' ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(color: _selectedCurrency == 'ZiG' ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

          // Amount input field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: Icon(
                _selectedCurrency == 'USD' ? Icons.attach_money : Icons.money_rounded,
                color: Colors.blueAccent,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
            ),
          ),
          const SizedBox(height: 16),

          // Gateway Selector
          const Text('Select Payment Method', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              fillColor: Colors.white.withOpacity(0.03),
              filled: true,
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

          // Pay Button
          ElevatedButton(
            onPressed: _isProcessing ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Pay Amount (${_selectedCurrency == 'USD' ? '\$' : ''}${_amountController.text} ${_selectedCurrency == 'ZiG' ? 'ZiG' : ''})'),
          ),
        ],
      ),
    );
  }
}
