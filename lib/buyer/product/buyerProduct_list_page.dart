import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:swift_order/models/product_model.dart';
import 'package:swift_order/service/cart_service.dart';

class BuyerProductListPage extends StatefulWidget {
  final String vendorId;

  const BuyerProductListPage({super.key, required this.vendorId});

  @override
  State<BuyerProductListPage> createState() => _BuyerProductListPageState();
}

class _BuyerProductListPageState extends State<BuyerProductListPage> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsRef = FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendorId)
        .collection('products');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 20,
                  bottom: 16,
                  right: 20,
                ),
                title: const Text(
                  "Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        // ignore: deprecated_member_use
                        theme.primaryColor.withOpacity(0.8),
                        theme.primaryColor,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                StreamBuilder<int>(
                  stream: Provider.of<CartService>(context).itemCountStream,
                  builder: (context, snapshot) {
                    final itemCount = snapshot.data ?? 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                        if (itemCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                itemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildCategoriesFilter(theme),
                ),
              ),
            ),

            // Vendor Info
            SliverToBoxAdapter(
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(widget.vendorId)
                        .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final vendorData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // ignore: deprecated_member_use
                            color: theme.primaryColor.withOpacity(0.1),
                          ),
                          child:
                              vendorData['imageUrl'] != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      vendorData['imageUrl'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Icon(
                                    Icons.store,
                                    color: theme.primaryColor,
                                    size: 30,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorData['vendorName'] ?? 'Vendor',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (vendorData['vendorDescription'] != null)
                                Text(
                                  vendorData['vendorDescription'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vendorData['rating']?.toString() ?? '4.5',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
            ),

            // Products List
            StreamBuilder<QuerySnapshot>(
              stream:
                  _selectedCategory == 'All'
                      ? productsRef
                          .orderBy('timestamp', descending: true)
                          .snapshots()
                      : productsRef
                          .where('category', isEqualTo: _selectedCategory)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No products available')),
                  );
                }

                final products =
                    snapshot.data!.docs.map((doc) {
                      // Update categories
                      if (doc.data() is Map<String, dynamic>) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['category'] != null &&
                            !_categories.contains(data['category'])) {
                          setState(() {
                            _categories.add(data['category']);
                          });
                        }
                      }
                      return Product.fromFirestore(doc);
                    }).toList();

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return _buildEnhancedProductCard(context, product);
                    }, childCount: products.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter(ThemeData theme) {
    return Container(
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedProductCard(BuildContext context, Product product) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to product detail page if needed
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child:
                    product.productImage != null
                        ? Image.network(
                          product.productImage!,
                          fit: BoxFit.cover,
                        )
                        : Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (product.category != null &&
                                product.category!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product.category!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'RM ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey[600], height: 1.3),
                  ),
                  const SizedBox(height: 16),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Favorites button or other action
                      IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {},
                      ),

                      // Add to cart button with quantity selector
                      _AddToCartButton(
                        product: product,
                        cartService: cartService,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  final Product product;
  final CartService cartService;

  const _AddToCartButton({required this.product, required this.cartService});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _isAdding = false;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isAdding) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    if (_quantity > 1) _quantity--;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                _quantity.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _quantity++;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(Icons.add, size: 16, color: theme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () async {
                await _addToCart();
                setState(() {
                  _isAdding = false;
                  _quantity = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.add_shopping_cart, size: 18),
      label: const Text('Add to Cart'),
      onPressed: () {
        setState(() {
          _isAdding = true;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(120, 40),
      ),
    );
  }

  Future<void> _addToCart() async {
    try {
      await widget.cartService.addToCart(widget.product, quantity: _quantity);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${widget.product.name} (x$_quantity) to cart'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              await widget.cartService.removeFromCart(widget.product.id);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }
}
