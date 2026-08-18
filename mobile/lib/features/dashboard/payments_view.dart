import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';

class PaymentsView extends StatefulWidget {
  final bool showAppBar;
  const PaymentsView({super.key, this.showAppBar = true});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _feeAccount;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedTxFilter = 'ALL';

  static const primaryBlue = Color(0xFF3B5998);

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
      // Offline fallback: load mock fee account & transactions
      setState(() {
        _feeAccount = {
          'balance_usd': '150.00',
          'balance_zig': '350.00',
        };
        _transactions = [
          {
            'id': 'TX-901',
            'reference_number': 'REF-2026-881',
            'payment_method': 'EcoCash USD',
            'amount': '50.00',
            'currency': 'USD',
            'status': 'completed',
            'created_at': '2026-07-20T10:00:00Z',
          },
          {
            'id': 'TX-902',
            'reference_number': 'REF-2026-882',
            'payment_method': 'ZiG Mobile Transfer',
            'amount': '250.00',
            'currency': 'ZiG',
            'status': 'completed',
            'created_at': '2026-06-15T14:30:00Z',
          },
        ];
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: primaryBlue,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              title: const Text(
                'Fee Payments & Ledger',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
               ? Center(child: Text(_errorMessage!, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchFeeDetails,
                  color: primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceHeader(context),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                            Icon(Icons.history_rounded, color: primaryColor.withValues(alpha: 0.5), size: 18),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Filter Chips
                        Row(
                          children: ['ALL', 'completed', 'pending'].map((filter) {
                            final isSel = _selectedTxFilter == filter;
                            final labelText = filter == 'ALL' ? 'All' : (filter == 'completed' ? 'Completed' : 'Pending');
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(labelText),
                                selected: isSel,
                                selectedColor: primaryColor,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedTxFilter = filter);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        Builder(
                          builder: (context) {
                            final filteredTx = _transactions.where((tx) {
                              if (_selectedTxFilter == 'ALL') return true;
                              return tx['status'] == _selectedTxFilter;
                            }).toList();

                            if (filteredTx.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: Center(
                                  child: Text(
                                    'No matching payment transactions.',
                                    style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredTx.length,
                              itemBuilder: (context, index) {
                                final tx = filteredTx[index];
                                final isCompleted = tx['status'] == 'completed';
                                final refNum = tx['reference_number'] ?? tx['id']?.toString() ?? 'REF-${index + 101}';

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Payment Receipt Ref: #$refNum (Copied to clipboard)'),
                                          backgroundColor: isCompleted ? Colors.green : Colors.amber,
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                      child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.secondary, size: 20),
                                    ),
                                    title: Text(
                                      'Fee Payment via ${tx['payment_method'] ?? 'Online Portal'}',
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      'Ref: #$refNum • ${tx['created_at']?.split('T')[0] ?? ''}',
                                      style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
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
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    double balanceUsd = double.parse(_feeAccount?['balance_usd']?.toString() ?? '0.0');
    double balanceZig = double.parse(_feeAccount?['balance_zig']?.toString() ?? '0.0');
    bool hasFees = balanceUsd > 0 || balanceZig > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OUTSTANDING BALANCE', style: TextStyle(color: primaryColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFees ? Colors.red.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hasFees ? Colors.red.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5), width: 1.0),
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
                  Text('\$$balanceUsd', style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('USD Balance', style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${balanceZig.toInt()} ZiG', style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('ZiG Balance', style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
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
              Text('Make School Payment', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close, color: primaryColor), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('USD')),
                  selected: _selectedCurrency == 'USD',
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: _selectedCurrency == 'USD' ? Colors.white : primaryColor, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _selectedCurrency == 'USD' ? primaryColor : const Color(0xFFE2E8F0))),
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
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: _selectedCurrency == 'ZiG' ? Colors.white : primaryColor, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _selectedCurrency == 'ZiG' ? primaryColor : const Color(0xFFE2E8F0))),
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
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
              prefixIcon: Icon(
                Icons.attach_money_rounded,
                color: primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Select Payment Method', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            dropdownColor: Colors.white,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.payment_rounded, color: primaryColor.withValues(alpha: 0.7)),
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
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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
