import 'package:flutter/material.dart';

class UniformMarketplaceView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const UniformMarketplaceView({super.key, this.child});

  @override
  State<UniformMarketplaceView> createState() => _UniformMarketplaceViewState();
}

class _UniformMarketplaceViewState extends State<UniformMarketplaceView> with SingleTickerProviderStateMixin {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const accentGreen = Color(0xFF10B981);
  static const borderColor = Color(0xFFE2E8F0);

  late TabController _tabController;
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
      'description': 'High-density navy blue wool-blend blazer with official school chest emblem badge.',
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
      'description': 'Breathable 100% white cotton school shirts with reinforced collar and buttons.',
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
      'description': 'Tailored charcoal grey wool-polyester trousers / box-pleated skirt.',
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
      'description': 'Water-resistant zip jacket and track pants with fleece lining for sports days.',
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
      'description': 'Moisture-wicking polo shirt in official house colors (Red, Blue, Green, Yellow).',
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
      'description': 'Durable black leather shoes with orthotic support and non-slip rubber soles.',
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
      'description': 'Padded heel and toe turn-down school socks with turnover band.',
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _cartTotalUsd {
    return _cartItems.fold(0.0, (sum, item) => sum + (item['price_usd'] * item['qty']));
  }

  double get _cartTotalZig {
    return _cartItems.fold(0.0, (sum, item) => sum + (item['price_zig'] * item['qty']));
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
          onPressed: () => _tabController.animateTo(1),
        ),
      ),
    );
  }

  void _openItemDetailModal(Map<String, dynamic> item) {
    String selectedSize = item['sizes'][0];
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final priceUsd = (item['price_usd'] as double) * quantity;
          final priceZig = (item['price_zig'] as double) * quantity;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData, color: primaryBlue, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['category'],
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item['description'],
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT SIZE:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (item['sizes'] as List<String>).map((size) {
                    final isSelected = size == selectedSize;
                    return ChoiceChip(
                      label: Text(size),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedSize = size);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'QUANTITY:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: () => setModalState(() => quantity++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'USD \$${priceUsd.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                          ),
                          Text(
                            'ZiG ${priceZig.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _addToCart(item, selectedSize, quantity);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _checkoutOrder() {
    if (_cartItems.isEmpty) return;

    String selectedPayment = 'EcoCash USD';
    String collectionPoint = 'School Store (Main Campus)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.shopping_bag_rounded, color: primaryBlue, size: 28),
                SizedBox(width: 10),
                Text('Uniform Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDER SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  ..._cartItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['name']} (${item['selected_size']}) x${item['qty']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${(item['price_usd'] * item['qty']).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'USD \$${_cartTotalUsd.toStringAsFixed(2)} / ZiG ${_cartTotalZig.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('PAYMENT METHOD:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPayment,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: 'EcoCash USD', child: Text('EcoCash USD')),
                      DropdownMenuItem(value: 'ZiG Mobile Transfer', child: Text('ZiG Mobile Transfer')),
                      DropdownMenuItem(value: 'Visa / Mastercard', child: Text('Visa / Mastercard')),
                      DropdownMenuItem(value: 'School Ledger Wallet', child: Text('School Pre-paid Wallet')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPayment = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('COLLECTION POINT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: collectionPoint,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: 'School Store (Main Campus)', child: Text('School Store (Main Campus)')),
                      DropdownMenuItem(value: 'Deliver to Homeroom Teacher', child: Text('Deliver to Homeroom Teacher')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => collectionPoint = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentGreen, foregroundColor: Colors.white),
                onPressed: () {
                  final newOrderId = 'ORD-2026-${(1000 + _ordersHistory.length * 111)}';
                  final summaryText = _cartItems.map((i) => '${i['name']} (${i['selected_size']}) x${i['qty']}').join(', ');

                  setState(() {
                    _ordersHistory.insert(0, {
                      'order_id': newOrderId,
                      'date': 'August 03, 2026',
                      'items_summary': summaryText,
                      'total_usd': _cartTotalUsd,
                      'currency': 'USD',
                      'payment_method': selectedPayment,
                      'status': 'Processing — $collectionPoint',
                      'status_color': const Color(0xFFF59E0B),
                    });
                    _cartItems.clear();
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order #$newOrderId placed successfully! Receipt sent via SMS.'),
                      backgroundColor: accentGreen,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  _tabController.animateTo(1); // Switch to Orders tab
                },
                child: const Text('Confirm & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childName = widget.child?['name'] ?? 'Alice Chewe';
    final childSchool = widget.child?['school'] ?? 'Hillside Primary School';

    final filteredCatalog = _catalog.where((item) {
      final matchesCat = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (item['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item['description'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uniform Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('Official School Wear & Online Store', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Catalog & Store'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Cart & Orders'),
                  if (_cartItems.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Catalog & Store
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Context Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: secondaryBlue,
                        child: Icon(Icons.school_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shopping for: $childName',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                            Text(
                              childSchool,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 12, color: accentGreen),
                            SizedBox(width: 4),
                            Text('Verified Uniforms', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGreen)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search uniforms, sizes, or items...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Formal Wear', 'Sports & Physical Ed', 'Accessories & Footwear'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? primaryBlue : borderColor),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Uniform Items Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filteredCatalog.length,
                  itemBuilder: (context, index) {
                    final item = filteredCatalog[index];
                    return GestureDetector(
                      onTap: () => _openItemDetailModal(item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                height: 74,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item['icon'] as IconData, size: 40, color: primaryBlue),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['category'],
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'USD \$${(item['price_usd'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue),
                                    ),
                                    Text(
                                      'ZiG ${(item['price_zig'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: primaryBlue),
                                ),
                              ],
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

          // TAB 2: Cart & Orders History
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Shopping Cart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_cart_rounded, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Shopping Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                      ],
                    ),
                    if (_cartItems.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _cartItems.clear()),
                        child: const Text('Clear Cart', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_cartItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.remove_shopping_cart_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'Your cart is currently empty',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Browse the Uniform Catalog tab to add items.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Column(
                    children: List.generate(_cartItems.length, (index) {
                      final item = _cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, color: primaryBlue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    'Size: ${item['selected_size']} • Qty: ${item['qty']}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'USD \$${(item['price_usd'] * item['qty']).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                  onPressed: () {
                                    setState(() => _cartItems.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total USD:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('USD \$${_cartTotalUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total ZiG Equivalent:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('ZiG ${_cartTotalZig.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _checkoutOrder,
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: const Text('Proceed to Checkout & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Order History List
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text('Order History & Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: _ordersHistory.map((order) {
                    final Color statusColor = order['status_color'] as Color;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order['order_id'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order['status'],
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order['items_summary'],
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order['date']} • ${order['payment_method']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              Text(
                                'USD \$${(order['total_usd'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
