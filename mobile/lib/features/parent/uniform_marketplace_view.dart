import 'package:flutter/material.dart';
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

  // Uniform Catalog Data
  final List<Map<String, dynamic>> _catalog = [
    {
      'id': 'U-101',
      'name': 'Official Embroidered School Blazer',
      'category': 'Formal Wear',
      'price_usd': 45.00,
      'price_zig': 585.00,
      'sizes': ['Size 28', 'Size 30', 'Size 32', 'Size 34', 'Size 36'],
      'in_stock': true,
      'icon': Icons.checkroom_rounded,
      'description':
          'High-density navy blue wool-blend blazer with official school chest emblem badge.',
    },
    {
      'id': 'U-102',
      'name': 'Long-Sleeve Cotton Shirt (Pack of 2)',
      'category': 'Formal Wear',
      'price_usd': 22.00,
      'price_zig': 286.00,
      'sizes': ['Size 26', 'Size 28', 'Size 30', 'Size 32', 'Size 34'],
      'in_stock': true,
      'icon': Icons.dry_cleaning_rounded,
      'description':
          'Breathable 100% white cotton school shirts with reinforced collar and buttons.',
    },
    {
      'id': 'U-103',
      'name': 'School Trousers / Pleated Skirt',
      'category': 'Formal Wear',
      'price_usd': 25.00,
      'price_zig': 325.00,
      'sizes': ['Size 28', 'Size 30', 'Size 32', 'Size 34'],
      'in_stock': true,
      'icon': Icons.strikethrough_s_rounded,
      'description':
          'Tailored charcoal grey wool-polyester trousers / box-pleated skirt.',
    },
    {
      'id': 'U-104',
      'name': 'Full Athletics Tracksuit Set',
      'category': 'Sports & Physical Ed',
      'price_usd': 38.00,
      'price_zig': 494.00,
      'sizes': ['S', 'M', 'L', 'XL'],
      'in_stock': true,
      'icon': Icons.directions_run_rounded,
      'description':
          'Water-resistant zip jacket and track pants with fleece lining for sports days.',
    },
    {
      'id': 'U-105',
      'name': 'House Color Sports Polo Shirt',
      'category': 'Sports & Physical Ed',
      'price_usd': 14.00,
      'price_zig': 182.00,
      'sizes': ['S', 'M', 'L', 'XL'],
      'in_stock': true,
      'icon': Icons.sports_tennis_rounded,
      'description':
          'Moisture-wicking polo shirt in official house colors (Red, Blue, Green, Yellow).',
    },
    {
      'id': 'U-106',
      'name': 'Official Striped School Tie',
      'category': 'Accessories & Footwear',
      'price_usd': 8.00,
      'price_zig': 104.00,
      'sizes': ['Standard Boy', 'Standard Girl', 'Prefect Gold Thread'],
      'in_stock': true,
      'icon': Icons.military_tech_rounded,
      'description': 'Silk-finish woven tie featuring school crest stripes.',
    },
    {
      'id': 'U-107',
      'name': 'Genuine Leather School Shoes',
      'category': 'Accessories & Footwear',
      'price_usd': 32.00,
      'price_zig': 416.00,
      'sizes': ['Size 1', 'Size 2', 'Size 3', 'Size 4', 'Size 5', 'Size 6'],
      'in_stock': true,
      'icon': Icons.roller_skating_rounded,
      'description':
          'Durable black leather shoes with orthotic support and non-slip rubber soles.',
    },
    {
      'id': 'U-108',
      'name': 'Cotton Heavyweight School Socks (3 Pairs)',
      'category': 'Accessories & Footwear',
      'price_usd': 7.50,
      'price_zig': 97.50,
      'sizes': ['Small (9-12)', 'Medium (12-3)', 'Large (4-7)'],
      'in_stock': true,
      'icon': Icons.style_rounded,
      'description':
          'Padded heel and toe turn-down school socks with turnover band.',
    },
  ];

  // Cart State: Item ID -> Map of details {item, size, qty}
  final List<Map<String, dynamic>> _cartItems = [];

  // Mock Orders History
  final List<Map<String, dynamic>> _ordersHistory = [
    {
      'order_id': 'ORD-2026-9821',
      'date': 'July 25, 2026',
      'items_summary': 'Official School Blazer (Size 30) x1, School Tie x1',
      'total_usd': 53.00,
      'currency': 'USD',
      'payment_method': 'EcoCash USD',
      'status': 'Ready for Pickup at School Store',
      'status_color': const Color(0xFF10B981),
    },
    {
      'order_id': 'ORD-2026-8710',
      'date': 'May 12, 2026',
      'items_summary': 'Sports Polo Shirt (Size M) x2, Tracksuit Set x1',
      'total_usd': 66.00,
      'currency': 'USD',
      'payment_method': 'ZiG Mobile Transfer',
      'status': 'Delivered / Collected',
      'status_color': const Color(0xFF3B5998),
    },
  ];

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

  Widget _productVisual(Map<String, dynamic> item, {double height = 100}) =>
      Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            item['category'] == 'Sports & Physical Ed'
                ? Icons.directions_run_outlined
                : item['category'] == 'Formal Wear'
                ? Icons.checkroom_outlined
                : Icons.shopping_bag_outlined,
            size: 42,
            color: AppColors.primary,
          ),
        ),
      );

  void _openItemDetailModal(Map<String, dynamic> item) {
    String size = item['sizes'][0];
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
    String payment = 'EcoCash USD';
    String collection = 'School Store (Main Campus)';
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
                    'USD \$${_cartTotalUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'ZiG ${_cartTotalZig.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: payment,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                    ),
                    items:
                        [
                              'EcoCash USD',
                              'ZiG Mobile Transfer',
                              'Visa / Mastercard',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) update(() => payment = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: collection,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Collection point',
                    ),
                    items:
                        [
                              'School Store (Main Campus)',
                              'Deliver to Homeroom Teacher',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) update(() => collection = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final now = DateTime.now();
                        final id = 'ORD-${now.millisecondsSinceEpoch}';
                        setState(() {
                          _ordersHistory.insert(0, {
                            'order_id': id,
                            'date': '${now.day}/${now.month}/${now.year}',
                            'items_summary': _cartItems
                                .map(
                                  (i) =>
                                      '${i['name']} (${i['selected_size']}) ×${i['qty']}',
                                )
                                .join(', '),
                            'total_usd': _cartTotalUsd,
                            'currency': 'USD',
                            'payment_method': payment,
                            'status': 'Processing · $collection',
                            'status_color': AppColors.primary,
                          });
                          _cartItems.clear();
                          _section = 2;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order saved for this session.'),
                          ),
                        );
                      },
                      child: const Text('Place order'),
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
              if (catalog.isEmpty)
                const PageEmpty(
                  title: 'No matching items',
                  message: 'Try another category, item name or size.',
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
                          'USD \$${(order['total_usd'] as num).toStringAsFixed(2)}',
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
