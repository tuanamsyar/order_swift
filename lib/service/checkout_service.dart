import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/models/cart_item_model.dart';
import 'package:swift_order/models/order_model.dart';

class CheckoutService {
  Future<String?> checkout(
    BuildContext context,
    List<CartItem> cartItems,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      if (cartItems.isEmpty) return 'Cart is empty';

      // 1. Verify user wallet exists
      final userRef = FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId);
      final userSnapshot = await userRef.get();
      if (!userSnapshot.exists) return 'Wallet not found';

      // 2. Calculate total and check balance
      final userBalance = userSnapshot['balance'] ?? 0.0;
      final total = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      if (userBalance < total) return 'Insufficient wallet balance';

      final batch = FirebaseFirestore.instance.batch();
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
      final vendorStats = <String, Map<String, dynamic>>{};

      // 3. Process each cart item with vendor verification
      for (final item in cartItems) {
        final sellerId = item.sellerId;
        final vendorId = item.vendorId;

        // Verify vendor exists before processing
        final vendorDoc =
            await FirebaseFirestore.instance
                .collection('vendors')
                .doc(vendorId)
                .get();
        if (!vendorDoc.exists) {
          return 'Vendor ${item.vendorName} no longer exists';
        }

        // Update seller wallet
        final sellerRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(sellerId);
        final sellerSnapshot = await sellerRef.get();
        if (sellerSnapshot.exists) {
          batch.update(sellerRef, {
            'balance': FieldValue.increment(item.price * item.quantity),
          });
        }

        // Prepare sale data
        final saleData = {
          'saleId': FirebaseFirestore.instance.collection('sales').doc().id,
          'productId': item.productId,
          'vendorId': vendorId,
          'quantitySold': item.quantity,
          'totalAmount': item.price * item.quantity,
          'timestamp': FieldValue.serverTimestamp(),
          'buyerId': userId,
          'orderId': orderId,
          'vendorName': vendorDoc['vendorName'] ?? item.vendorName,
        };

        // Record sale in global collection
        batch.set(
          FirebaseFirestore.instance.collection('sales').doc(),
          saleData,
        );

        // Record sale in vendor's subcollection (only if vendor exists)
        batch.set(
          FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .collection('sales')
              .doc(),
          saleData,
        );

        // Update vendor stats
        vendorStats.update(
          vendorId,
          (stats) => {
            'totalSales':
                (stats['totalSales'] ?? 0) + (item.price * item.quantity),
            'totalOrders': (stats['totalOrders'] ?? 0) + 1,
            'totalProductsSold':
                (stats['totalProductsSold'] ?? 0) + item.quantity,
          },
          ifAbsent:
              () => {
                'totalSales': item.price * item.quantity,
                'totalOrders': 1,
                'totalProductsSold': item.quantity,
              },
        );
      }

      // 4. Batch update vendor analytics
      vendorStats.forEach((vendorId, stats) {
        final vendorRef = FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId);
        batch.update(vendorRef, {
          'totalSales': FieldValue.increment(stats['totalSales']),
          'totalOrders': FieldValue.increment(stats['totalOrders']),
          'totalProductsSold': FieldValue.increment(stats['totalProductsSold']),
        });
      });

      // 5. Deduct from buyer and create order
      batch.update(userRef, {'balance': FieldValue.increment(-total)});

      final primaryVendor =
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(cartItems.first.vendorId)
              .get();

      batch.set(
        FirebaseFirestore.instance.collection('orders').doc(orderId),
        OrderModel(
          orderId: orderId,
          buyerId: userId,
          items: cartItems,
          total: total,
          timestamp: DateTime.now(),
          status: 'Pending',
          vendorName: primaryVendor['vendorName'] ?? 'Unknown Vendor',
        ).toMap(),
      );

      // 6. Clear cart in separate operation (batches have limits)
      final cartSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart')
              .get();

      final clearCartBatch = FirebaseFirestore.instance.batch();
      for (final doc in cartSnapshot.docs) {
        clearCartBatch.delete(doc.reference);
      }

      // 7. Execute transactions
      await batch.commit();
      await clearCartBatch.commit();

      return orderId;
    } catch (e) {
      debugPrint('Checkout error: $e');
      return 'Checkout failed. Please try again.';
    }
  }
}
