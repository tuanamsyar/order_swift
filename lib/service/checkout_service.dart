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

      final userRef = FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId);
      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        return 'Wallet not found.';
      }

      final userBalance = userSnapshot['balance'] ?? 0.0;

      final total = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      if (userBalance < total) {
        return 'Insufficient wallet balance.';
      }

      final batch = FirebaseFirestore.instance.batch();

      // Update seller balances
      for (final item in cartItems) {
        final sellerRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(item.sellerId);
        final sellerSnapshot = await sellerRef.get();

        if (!sellerSnapshot.exists) continue;

        final currentSellerBalance = sellerSnapshot['balance'] ?? 0.0;
        final newSellerBalance =
            currentSellerBalance + (item.price * item.quantity);

        batch.update(sellerRef, {'balance': newSellerBalance});
      }

      // Deduct from buyer wallet
      final newUserBalance = userBalance - total;
      batch.update(userRef, {'balance': newUserBalance});

      // Generate the order ID
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
      // Fetch vendor name
      final vendorId =
          cartItems.first.vendorId; // assuming one vendor per order
      final vendorSnapshot =
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .get();

      final vendorName =
          vendorSnapshot.exists
              ? vendorSnapshot['vendorName'] ?? 'Unknown Vendor'
              : 'Unknown Vendor';

      final order = OrderModel(
        orderId: orderId,
        buyerId: userId,
        items: cartItems,
        total: total,
        timestamp: DateTime.now(),
        status: 'Pending',
        vendorName: vendorName, // ✅ Include this
      );

      batch.set(
        FirebaseFirestore.instance.collection('orders').doc(orderId),
        order.toMap(),
      );

      // Clear cart
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart');

      final cartSnapshot = await cartRef.get();
      for (final doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return orderId; // ✅ Return this for navigation to order detail
    } catch (e) {
      return 'Checkout failed: $e';
    }
  }
}
