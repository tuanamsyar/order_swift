import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // 'purchase', 'refund', 'topup', 'withdrawal'
  final String? orderId;
  final String description;
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.orderId,
    required this.description,
    required this.timestamp,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? '',
      orderId: map['orderId'],
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'orderId': orderId,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
