import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swift_order/models/cart_item_model.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final List<CartItem> items;
  final double total;
  final DateTime timestamp;
  final String status;
  final String vendorName;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    required this.total,
    required this.timestamp,
    this.status = 'Pending',
    required this.vendorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'total': total,
      'timestamp': timestamp,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status,
      'vendorName': vendorName,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      vendorName: map['vendorName'] ?? 'Unknown Vendor', // 👈 Fix here
      items: List<CartItem>.from(
        map['items']?.map((item) => CartItem.fromMap(item)) ?? [],
      ),
      total: (map['total'] ?? 0).toDouble(),
      timestamp:
          map['timestamp']?.toDate() ?? DateTime.now(), // 👈 Convert Timestamp
      status: map['status'] ?? 'Pending', // 👈 Fix here
    );
  }
}
