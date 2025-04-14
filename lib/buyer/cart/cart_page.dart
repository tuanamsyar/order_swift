import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_order/models/cart_item_model.dart';
import 'package:swift_order/service/cart_service.dart';
import 'package:swift_order/service/checkout_service.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartService.getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartItems =
              snapshot.data!.docs.map((doc) {
                return CartItem.fromFirestore(doc);
              }).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(context, item, cartService);
                  },
                ),
              ),
              _buildCheckoutSection(context, cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartService cartService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image:
                    item.imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(item.imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child: item.imageUrl == null ? const Icon(Icons.fastfood) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM ${item.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
            // Quantity controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () async {
                    if (item.quantity > 1) {
                      await cartService.updateCartItemQuantity(
                        item.productId,
                        item.quantity - 1,
                      );
                    } else {
                      await cartService.removeFromCart(item.productId);
                    }
                  },
                ),
                Text(item.quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await cartService.updateCartItemQuantity(
                      item.productId,
                      item.quantity + 1,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, List<CartItem> cartItems) {
    final total = cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'RM ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (cartItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart is empty')),
                  );
                  return;
                }

                // Optional: Show loading while processing
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (_) => const Center(child: CircularProgressIndicator()),
                );

                final checkoutService = CheckoutService();
                final result = await checkoutService.checkout(
                  context,
                  cartItems,
                );

                if (context.mounted) Navigator.pop(context); // Dismiss loading

                if (context.mounted) {
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkout successful!')),
                    );
                    Navigator.pop(context); // Go back after successful checkout
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result)));
                  }
                }
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
