import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Stripe (call this in your main.dart)
  static Future<void> initStripe(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  // Get wallet balance stream
  Stream<double> getBalanceStream(String userId) {
    return _firestore
        .collection('wallets')
        .doc(userId)
        .snapshots()
        .map((snapshot) => (snapshot.data()?['balance'] ?? 0.0).toDouble());
  }

  // Get current wallet balance
  Future<double> getWalletBalance(String userId) async {
    final doc = await _firestore.collection('wallets').doc(userId).get();
    return (doc.data()?['balance'] ?? 0.0).toDouble();
  }

  // Top up wallet with Stripe payment
  Future<void> topUpWithStripe({
    required String userId,
    required double amount,
    required String currency,
    required String stripeSecretKey,
  }) async {
    try {
      // 1. Create payment intent
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        stripeSecretKey: stripeSecretKey,
      );

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Swift Order',
          style: ThemeMode.light,
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Update wallet balance
      await _updateWalletBalance(userId, amount);
    } on StripeException catch (e) {
      throw StripePaymentException(
        e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Update wallet balance (can be used for both top-ups and deductions)
  Future<void> _updateWalletBalance(String userId, double amount) async {
    await _firestore.collection('wallets').doc(userId).update({
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create payment intent (in production, move this to your backend)
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String stripeSecretKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0),
          'currency': currency.toLowerCase(),
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Stripe API error: $e');
    }
  }

  // Initialize wallet for new user
  Future<void> initializeWallet(String userId) async {
    await _firestore.collection('wallets').doc(userId).set({
      'balance': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class StripePaymentException implements Exception {
  final String message;
  StripePaymentException(this.message);

  @override
  String toString() => message;
}
