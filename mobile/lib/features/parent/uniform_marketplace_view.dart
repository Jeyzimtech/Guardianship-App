import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class UniformMarketplaceView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const UniformMarketplaceView({super.key, this.child});

  @override
  State<UniformMarketplaceView> createState() => _UniformMarketplaceViewState();
}

class _UniformMarketplaceViewState extends State<UniformMarketplaceView> {
  static const accentGreen = AppColors.primaryLight;

  int _section = 0;
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<Map<String, dynamic>> _catalog = [];
  bool _loadingCatalog = true;
  bool _loadingOrders = false;
  List<Map<String, dynamic>> _ordersHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOrders());
  }

  Future<void> _fetchOrders() async {
    final studentId =
        widget.child?['id'] ??
        (mounted
            ? (context.read<StudentProvider>().selectedStudent?['id'])
            : null);
    if (studentId == null) return;
    setState(() => _loadingOrders = true);
    try {
      final response = await context.read<StudentProvider>().apiClient.dio.get(
        '/uniform-orders/$studentId',
      );
      final values = (response.data['orders'] as List? ?? [])
          .map((order) {
            final data = Map<String, dynamic>.from(order);
            return {
              'id': data['id'],
              'pending': data['payment_status'] == 'pending',
              'reference': data['payment_reference'],
              'order_id': 'ORD-${data['id']}',
              'date': data['created_at']?.toString().split('T').first ?? '',
              'items_summary': (data['items'] as List? ?? [])
                  .map(
                    (line) =>
                        '${line['name']} (${line['size']}) ×${line['quantity']}',
                  )
                  .join(', '),
              'total_amount': data['total_amount'],
              'currency': data['currency'],
              'status': data['payment_status'] == 'pending'
                  ? 'Payment pending'
                  : data['payment_status'] == 'paid' &&
                        data['latest_payment']?['sandbox'] == true
                  ? 'Test payment verified'
                  : data['payment_status'],
              'payment_method': data['payment_status'] == 'paid'
                  ? 'Payment verified${data['payment_method'] == 'PesePay' ? ' by PesePay' : ''}.'
                  : data['payment_reference'] == null
                  ? 'Complete checkout securely with PesePay.'
                  : 'Reference: ${data['payment_reference']} · awaiting school verification',
            };
          })
          .cast<Map<String, dynamic>>()
          .toList();
      if (mounted) setState(() => _ordersHistory = values);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load uniform orders.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  int? _payingOrder;
  Future<void> _pay(int orderId, {bool checkOnly = false}) async {
    if (_payingOrder != null) return;
    setState(() => _payingOrder = orderId);
    try {
      final api = context.read<StudentProvider>().apiClient.dio;
      final response = checkOnly
          ? await api.get('/uniform-orders/$orderId/payment-status')
          : await api.post('/uniform-orders/$orderId/checkout');
      if (!mounted) return;
      if (checkOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['payment_status'] == 'paid'
                  ? 'Payment verified. Your order is paid.'
                  : 'Payment status: ${response.data['gateway_status'] ?? response.data['payment_status']}',
            ),
          ),
        );
      } else {
        if (response.data['sandbox'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'PesePay test checkout. No real money will be collected.',
              ),
            ),
          );
        }
        final uri = Uri.tryParse(response.data['redirect_url'] ?? '');
        if (uri == null ||
            uri.scheme != 'https' ||
            !(uri.host == 'pesepay.com' ||
                uri.host.endsWith('.pesepay.com') ||
                (response.data['sandbox'] == true &&
                    uri.host == 'pesepay-payments-sandbox-test.web.app'))) {
          throw Exception('Invalid payment link.');
        }
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not open PesePay.');
        }
      }
      if (mounted) await _fetchOrders();
    } catch (e) {
      if (mounted) {
        final message = e is DioException && e.response?.data is Map
            ? e.response!.data['message']?.toString()
            : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ??
                  'Could not open or verify payment. Your order is saved; please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _payingOrder = null);
    }
  }

  Future<void> _fetchLiveCatalog() async {
    setState(() => _loadingCatalog = true);
    try {
      final dio = context.read<StudentProvider>().apiClient.dio;
      final schoolId =
          widget.child?['school_id'] ??
          (mounted
              ? (context.read<StudentProvider>().selectedStudent?['school_id'])
              : null);
      final res = await dio.get(
        '/uniforms',
        queryParameters: schoolId == null ? null : {'school_id': schoolId},
      );
      if (res.statusCode == 200 &&
          res.data != null &&
          res.data['uniforms'] != null) {
        final list = List<Map<String, dynamic>>.from(
          (res.data['uniforms'] as List).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
        if (mounted) {
          setState(() {
            _catalog = list;
            _loadingCatalog = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Live uniform catalog fetch error: $e');
    }
    if (mounted) {
      setState(() {
        _catalog = [];
        _loadingCatalog = false;
      });
    }
  }

  // Cart State: Item ID -> Map of details {item, size, qty}
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _cartTotalUsd {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item['price_usd'] * item['qty']),
    );
  }

  double get _cartTotalZig {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item['price_zig'] * item['qty']),
    );
  }

  void _addToCart(Map<String, dynamic> item, String selectedSize, int qty) {
    final existingIndex = _cartItems.indexWhere(
      (c) => c['id'] == item['id'] && c['selected_size'] == selectedSize,
    );

    setState(() {
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['qty'] += qty;
      } else {
        _cartItems.add({
          'id': item['id'],
          'name': item['name'],
          'price_usd': item['price_usd'],
          'price_zig': item['price_zig'],
          'selected_size': selectedSize,
          'qty': qty,
          'icon': item['icon'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} ($selectedSize) added to cart!'),
        backgroundColor: accentGreen,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => setState(() => _section = 1),
        ),
      ),
    );
  }

  Widget _productVisual(Map<String, dynamic> item, {double height = 120}) {
    final imageUrl = item['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(item),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            )
          : _fallbackIcon(item),
    );
  }

  Widget _fallbackIcon(Map<String, dynamic> item) {
    return Center(
      child: Icon(
        item['category'] == 'Sports & Physical Ed'
            ? Icons.directions_run_outlined
            : item['category'] == 'Formal Wear'
            ? Icons.checkroom_outlined
            : Icons.shopping_bag_outlined,
        size: 42,
        color: AppColors.primary,
      ),
    );
  }

  void _openItemDetailModal(Map<String, dynamic> item) {
    final sizesList = (item['sizes'] as List?) ?? ['Standard'];
    String size = sizesList.isNotEmpty ? sizesList[0].toString() : 'Standard';
    int qty = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * .8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _productVisual(item, height: 120),
                  const SizedBox(height: 20),
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['description'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose your size',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (item['sizes'] as List)
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: size == value,
                            onSelected: (_) => update(() => size = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Decrease quantity',
                            onPressed: qty > 1
                                ? () => update(() => qty--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Increase quantity',
                            onPressed: () => update(() => qty++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'USD \$${(item['price_usd'] * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ZiG ${(item['price_zig'] * qty).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: item['in_stock'] == true
                          ? () {
                              Navigator.pop(ctx);
                              _addToCart(item, size, qty);
                            }
                          : null,
                      child: Text(
                        item['in_stock'] == true
                            ? 'Add to bag'
                            : 'Out of stock',
                      ),
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

  void _checkoutOrder() {
    if (_cartItems.isEmpty) return;
    bool placing = false;
    String? orderError;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * .8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review your order',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  for (final item in _cartItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['selected_size']} · Qty ${item['qty']}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Items: USD \$${_cartTotalUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pay securely on the PesePay payment page. Return to your order and check payment status after checkout.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Collection: your school. Contact the school for collection details.',
                  ),
                  if (orderError != null)
                    Text(
                      orderError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: placing
                          ? null
                          : () async {
                              final studentId =
                                  widget.child?['id'] ??
                                  context
                                      .read<StudentProvider>()
                                      .selectedStudent?['id'];
                              if (studentId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Link a child to your account before ordering.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              update(() => placing = true);
                              try {
                                final response = await context
                                    .read<StudentProvider>()
                                    .apiClient
                                    .dio
                                    .post(
                                      '/uniform-orders',
                                      data: {
                                        'student_id': studentId,
                                        'currency': 'USD',
                                        'items': _cartItems
                                            .map(
                                              (item) => {
                                                'uniform_id': item['id'],
                                                'size': item['selected_size'],
                                                'quantity': item['qty'],
                                              },
                                            )
                                            .toList(),
                                      },
                                    );
                                if (response.data?['status'] != 'success') {
                                  throw Exception('Order was not accepted.');
                                }
                                if (!mounted || !ctx.mounted) return;
                                setState(() {
                                  _cartItems.clear();
                                  _section = 2;
                                });
                                Navigator.pop(ctx);
                                await _fetchOrders();
                                final orderId = response.data['order']?['id'];
                                if (orderId is int && mounted) {
                                  await _pay(orderId);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order saved. Complete payment with PesePay.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (!ctx.mounted) return;
                                update(() {
                                  placing = false;
                                  orderError = error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                                });
                              }
                            },
                      child: Text(placing ? 'Saving order...' : 'Place order'),
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

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog
        .where(
          (item) =>
              (_selectedCategory == 'All' ||
                  item['category'] == _selectedCategory) &&
              '${item['name']} ${item['description']} ${item['sizes']}'
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
        )
        .toList();
    final count = _cartItems.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int),
    );
    final tabs = ['Shop', 'Bag ($count)', 'Orders'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Uniform store'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeading(
              title: 'Uniform store',
              subtitle: 'School essentials, ready for every day.',
              symbol: AppSymbol.store,
              icon: Icons.shopping_bag_outlined,
            ),
            PageFilters(
              labels: tabs,
              selected: tabs[_section],
              onSelected: (value) =>
                  setState(() => _section = tabs.indexOf(value)),
            ),
            const SizedBox(height: 24),
            if (_section == 0) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE SCHOOL COLLECTION',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'A fresh start.\nThe right fit.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Uniforms, sportswear and everyday essentials.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search items or sizes',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              PageFilters(
                labels: const [
                  'All',
                  'Formal Wear',
                  'Sports & Physical Ed',
                  'Accessories & Footwear',
                ],
                selected: _selectedCategory,
                onSelected: (value) =>
                    setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 20),
              Text(
                '${catalog.length} essentials',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingCatalog)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (catalog.isEmpty)
                const PageEmpty(
                  title: 'No matching items',
                  message:
                      'No uniform items found in the school store catalog.',
                ),
              for (final item in catalog)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openItemDetailModal(item),
                      child: PageCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _productVisual(item),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PageBadge(item['category']),
                                if (item['in_stock'] != true)
                                  const PageBadge(
                                    'Out of stock',
                                    color: AppColors.error,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'USD \$${(item['price_usd'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ZiG ${(item['price_zig'] as num).toStringAsFixed(2)} · ${item['sizes'].length} sizes',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Choose size',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            if (_section == 1) ...[
              if (_cartItems.isEmpty) ...[
                const PageEmpty(
                  title: 'Your bag is waiting',
                  message:
                      'Choose your school essentials and select a size to get started.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _section = 0),
                  child: const Text('Browse uniforms'),
                ),
              ],
              for (final item in _cartItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PageBadge(item['selected_size']),
                        const SizedBox(height: 12),
                        Text(
                          'USD \$${(item['price_usd'] * item['qty']).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Wrap(
                          spacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Decrease quantity',
                                  onPressed: item['qty'] > 1
                                      ? () => setState(() => item['qty']--)
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Text('${item['qty']}'),
                                IconButton(
                                  tooltip: 'Increase quantity',
                                  onPressed: () =>
                                      setState(() => item['qty']++),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _cartItems.remove(item)),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (_cartItems.isNotEmpty)
                PageCard(
                  color: AppColors.softBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order total',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'USD \$${_cartTotalUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'ZiG ${_cartTotalZig.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _checkoutOrder,
                          child: const Text('Review order'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (_section == 2) ...[
              const Text(
                'Your orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (_loadingOrders)
                const Center(child: CircularProgressIndicator()),
              if (!_loadingOrders && _ordersHistory.isEmpty)
                const PageEmpty(
                  title: 'No orders yet',
                  message: 'Orders placed for your child will appear here.',
                ),
              for (final order in _ordersHistory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageBadge(order['status']),
                        const SizedBox(height: 16),
                        Text(
                          order['order_id'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order['date'],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          order['items_summary'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${order['currency']} ${order['total_amount']}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order['payment_method'],
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        if (order['pending'] == true)
                          TextButton(
                            onPressed: _payingOrder == null
                                ? () =>
                                      _pay(order['id'] as int, checkOnly: true)
                                : null,
                            child: const Text('Check payment status'),
                          ),
                        if (order['pending'] == true)
                          TextButton(
                            onPressed: _payingOrder == null
                                ? () => _pay(order['id'] as int)
                                : null,
                            child: Text(
                              _payingOrder == order['id']
                                  ? 'Please wait...'
                                  : 'Pay with PesePay',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
