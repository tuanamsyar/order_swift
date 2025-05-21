import 'package:cloud_firestore/cloud_firestore.dart';

class SaleRecord {
  final String saleId;
  final String orderId;
  final String vendorId;
  final String sellerId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double totalAmount;
  final DateTime saleDate;

  SaleRecord({
    required this.saleId,
    required this.orderId,
    required this.vendorId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.saleDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'orderId': orderId,
      'vendorId': vendorId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'saleDate': Timestamp.fromDate(saleDate),
      'monthYear': '${saleDate.month}-${saleDate.year}', // For easy querying
    };
  }

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    return SaleRecord(
      saleId: map['saleId'],
      orderId: map['orderId'],
      vendorId: map['vendorId'],
      sellerId: map['sellerId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      price: map['price'].toDouble(),
      totalAmount: map['totalAmount'].toDouble(),
      saleDate: (map['saleDate'] as Timestamp).toDate(),
    );
  }
}
