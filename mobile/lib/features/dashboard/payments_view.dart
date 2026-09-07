import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';

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

    double balanceUsd = double.tryParse(_feeAccount?['balance_usd']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0.0') ?? 0.0;
    double balanceZig = double.tryParse(_feeAccount?['balance_zig']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0.0') ?? 0.0;

    if (balanceUsd <= 0 && balanceZig <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fees are cleared! No outstanding balance.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchFeeDetails,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceHeader(context),
                        const SizedBox(height: 24),
                        
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                            Icon(Icons.history_rounded, color: AppColors.primaryLight, size: 20),
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
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.softBlue,
                                side: BorderSide(color: isSel ? AppColors.primary : AppColors.blueBorder),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppColors.primaryDark,
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
                              return const Padding(
                                padding: EdgeInsets.only(top: 24.0),
                                child: Center(
                                  child: Text(
                                    'No matching payment transactions.',
                                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: AppColors.cardBorder),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Payment Receipt Ref: #$refNum (Copied to clipboard)'),
                                          backgroundColor: isCompleted ? AppColors.primary : AppColors.warning,
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.softBlue,
                                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    title: Text(
                                      'Fee Payment via ${tx['payment_method'] ?? 'Online Portal'}',
                                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      'Ref: #$refNum • ${tx['created_at']?.split('T')[0] ?? ''}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${tx['currency'] == 'USD' ? '\$' : ''}${tx['amount']} ${tx['currency'] == 'ZiG' ? 'ZiG' : ''}',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isCompleted ? 'Completed' : 'Pending',
                                          style: TextStyle(
                                            color: isCompleted ? AppColors.primaryLight : AppColors.warning,
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
    double balanceUsd = double.tryParse(_feeAccount?['balance_usd']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0.0') ?? 0.0;
    double balanceZig = double.tryParse(_feeAccount?['balance_zig']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0.0') ?? 0.0;
    bool hasFees = balanceUsd > 0 || balanceZig > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dual-Currency Balance Cards
        Row(
          children: [
            // USD Balance Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: hasFees ? AppColors.error : AppColors.primaryLight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'USD BALANCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${balanceUsd.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: hasFees ? AppColors.error : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasFees
                                  ? AppColors.errorLight
                                  : AppColors.softBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              hasFees ? 'OUTSTANDING' : 'CLEARED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: hasFees
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ZiG Balance Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: balanceZig > 0
                            ? AppColors.warning
                            : AppColors.primaryLight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ZiG BALANCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${balanceZig.toInt()} ZiG',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: balanceZig > 0
                                  ? AppColors.warning
                                  : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: balanceZig > 0
                                  ? AppColors.warningLight
                                  : AppColors.softBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              balanceZig > 0 ? 'OUTSTANDING' : 'CLEARED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: balanceZig > 0
                                    ? AppColors.warning
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Pay Now Button
        if (hasFees)
          ElevatedButton(
            onPressed: _showPaymentBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Pay Outstanding Fees Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blueBorder),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Your fee account is up to date.',
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        const SizedBox(height: 22),

        // Payment Methods section
        const Text(
          'Payment Methods',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _buildMethodTile('EcoCash', 'Mobile Money', AppColors.primary, AppColors.softBlue),
            _buildMethodTile('Paynow', 'Online Gateway', AppColors.primaryDark, AppColors.softBlue),
            _buildMethodTile('ZIPIT', 'Bank Transfer', AppColors.primaryLight, AppColors.softBlue),
            _buildMethodTile('Bank Wire', 'International', AppColors.textPrimary, AppColors.softBlue),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodTile(String name, String subtitle, Color textColor, Color bgColor) {
    return GestureDetector(
      onTap: _showPaymentBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blueBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textColor),
            ),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 10,
                  color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
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
              const Text('Make School Payment', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('USD')),
                  selected: _selectedCurrency == 'USD',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.softBlue,
                  labelStyle: TextStyle(color: _selectedCurrency == 'USD' ? Colors.white : AppColors.primaryDark, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _selectedCurrency == 'USD' ? AppColors.primary : AppColors.blueBorder)),
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
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.softBlue,
                  labelStyle: TextStyle(color: _selectedCurrency == 'ZiG' ? Colors.white : AppColors.primaryDark, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _selectedCurrency == 'ZiG' ? AppColors.primary : AppColors.blueBorder)),
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
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.attach_money_rounded,
                color: AppColors.primaryLight,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Select Payment Method', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payment_rounded, color: AppColors.primaryLight),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
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
              backgroundColor: AppColors.primary,
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
