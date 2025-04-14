import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.userId,
    required this.balance,
    this.currency = 'MYR',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert model to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create model from Firestore document
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      userId: map['userId'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'MYR',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create empty/default wallet
  factory Wallet.empty(String userId) {
    final now = DateTime.now();
    return Wallet(userId: userId, balance: 0.0, createdAt: now, updatedAt: now);
  }

  // Copy with method for immutability
  Wallet copyWith({
    String? userId,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
