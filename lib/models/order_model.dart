import 'package:swift_order/models/cart_item_model.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final List<CartItem> items;
  final double total;
  final DateTime timestamp;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    required this.total,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'total': total,
      'timestamp': timestamp,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
