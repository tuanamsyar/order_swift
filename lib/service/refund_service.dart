import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/models/order_model.dart';
import 'package:swift_order/models/wallet_transaction_model.dart';

class RefundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request a refund for an order
  Future<void> requestRefund({
    required String orderId,
    required String buyerId,
    required String reason,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'refundRequested': true,
      'refundReason': reason,
      'status': 'Refund Requested',
    });
  }

  // Process a refund (to be called by admin or vendor)
  Future<void> processRefund({
    required String orderId,
    required String buyerId,
    required String vendorId,
    required double amount,
  }) async {
    // Validate inputs
    if (orderId.isEmpty || buyerId.isEmpty || vendorId.isEmpty) {
      throw Exception('Invalid IDs provided for refund');
    }

    // Verify order exists and is in correct status
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    final orderData = orderDoc.data();
    if (orderData?['status'] != 'Refund Requested') {
      throw Exception('Order is not in refund requested state');
    }

    // Verify wallets exist
    final buyerWallet =
        await _firestore.collection('wallets').doc(buyerId).get();
    final vendorWallet =
        await _firestore.collection('wallets').doc(vendorId).get();

    if (!buyerWallet.exists || !vendorWallet.exists) {
      throw Exception('One or more wallets not found');
    }

    // Process refund in a transaction
    await _firestore.runTransaction((transaction) async {
      // Update order status
      transaction.update(_firestore.collection('orders').doc(orderId), {
        'status': 'Refunded',
        'refundProcessedAt': FieldValue.serverTimestamp(),
      });

      // Update buyer's wallet
      transaction.update(_firestore.collection('wallets').doc(buyerId), {
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add buyer transaction
      transaction.set(
        _firestore
            .collection('wallets')
            .doc(buyerId)
            .collection('transactions')
            .doc(),
        {
          'amount': amount,
          'type': 'refund',
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Refund for order #$orderId',
        },
      );

      // Update vendor's wallet
      transaction.update(_firestore.collection('wallets').doc(vendorId), {
        'balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add vendor transaction
      transaction.set(
        _firestore
            .collection('wallets')
            .doc(vendorId)
            .collection('transactions')
            .doc(),
        {
          'amount': -amount,
          'type': 'refund',
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Refund for order #$orderId',
        },
      );
    });
  }

  // Check if refund can be requested
  Future<bool> canRequestRefund(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return false;

    final status = doc.data()?['status'] as String?;
    return status == 'Pending' || status == 'Processed';
  }

  // Get refund requests for vendor
  Stream<List<OrderModel>> getRefundRequestsForVendor(String vendorId) {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'Refund Requested')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => OrderModel.fromMap(doc.data()))
                  .toList(),
        );
  }
}
