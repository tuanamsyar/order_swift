import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swift_order/models/cart_item_model.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final List<CartItem> items;
  final double total;
  final DateTime timestamp;
  final String
  status; // 'Pending', 'Processed', 'Completed', 'Refund Requested', 'Refunded'
  final String vendorName;
  final String? vendorId;
  final bool refundRequested;
  final String? refundReason;
  final DateTime? refundProcessedAt;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String? buyerPhone;
  final String? notes;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    required this.total,
    required this.timestamp,
    this.status = 'Pending',
    required this.vendorName,
    this.vendorId,
    this.refundRequested = false,
    this.refundReason,
    this.refundProcessedAt,
    this.paymentMethod,
    this.deliveryAddress,
    this.buyerPhone,
    this.notes,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'timestamp': timestamp,
      'status': status,
      'vendorName': vendorName,
      if (vendorId != null) 'vendorId': vendorId,
      'refundRequested': refundRequested,
      if (refundReason != null) 'refundReason': refundReason,
      if (refundProcessedAt != null) 'refundProcessedAt': refundProcessedAt,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (buyerPhone != null) 'buyerPhone': buyerPhone,
      if (notes != null) 'notes': notes,
    };
  }

  // Create from Firestore map
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    try {
      // Helper to parse timestamp from various formats
      DateTime? parseTimestamp(dynamic timestamp) {
        if (timestamp == null) return null;
        if (timestamp is Timestamp) return timestamp.toDate();
        if (timestamp is DateTime) return timestamp;
        if (timestamp is String) return DateTime.tryParse(timestamp);
        return null;
      }

      return OrderModel(
        orderId: map['orderId']?.toString() ?? '',
        buyerId: map['buyerId']?.toString() ?? '',
        items:
            (map['items'] as List<dynamic>?)?.map((item) {
              return CartItem.fromMap(
                item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{},
              );
            }).toList() ??
            [],
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        timestamp: parseTimestamp(map['timestamp']) ?? DateTime.now(),
        status: map['status']?.toString() ?? 'Pending',
        vendorName: map['vendorName']?.toString() ?? 'Unknown Vendor',
        vendorId: map['vendorId']?.toString(),
        refundRequested: map['refundRequested'] as bool? ?? false,
        refundReason: map['refundReason']?.toString(),
        refundProcessedAt: parseTimestamp(map['refundProcessedAt']),
        paymentMethod: map['paymentMethod']?.toString(),
        deliveryAddress: map['deliveryAddress']?.toString(),
        buyerPhone: map['buyerPhone']?.toString(),
        notes: map['notes']?.toString(),
      );
    } catch (e) {
      // Fallback constructor with error status for debugging
      return OrderModel(
        orderId: 'error-${DateTime.now().millisecondsSinceEpoch}',
        buyerId: '',
        items: [],
        total: 0.0,
        timestamp: DateTime.now(),
        vendorName: 'Error Vendor',
        status: 'Error',
      );
    }
  }

  // Copy with method for immutability
  OrderModel copyWith({
    String? orderId,
    String? buyerId,
    List<CartItem>? items,
    double? total,
    DateTime? timestamp,
    String? status,
    String? vendorName,
    String? vendorId,
    bool? refundRequested,
    String? refundReason,
    DateTime? refundProcessedAt,
    String? paymentMethod,
    String? deliveryAddress,
    String? buyerPhone,
    String? notes,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      items: items ?? this.items,
      total: total ?? this.total,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      vendorName: vendorName ?? this.vendorName,
      vendorId: vendorId ?? this.vendorId,
      refundRequested: refundRequested ?? this.refundRequested,
      refundReason: refundReason ?? this.refundReason,
      refundProcessedAt: refundProcessedAt ?? this.refundProcessedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  bool get canRequestRefund =>
      (status == 'Pending' || status == 'Processed') && !refundRequested;

  bool get canProcessRefund => status == 'Refund Requested' && refundRequested;

  bool get isRefunded => status == 'Refunded';

  bool get isValid => orderId.isNotEmpty && buyerId.isNotEmpty;

  // Format order date
  String formattedDate([String format = 'MMM dd, yyyy']) {
    return DateFormat(format).format(timestamp);
  }

  // Format refund date if available
  String? formattedRefundDate([String format = 'MMM dd, yyyy']) {
    return refundProcessedAt != null
        ? DateFormat(format).format(refundProcessedAt!)
        : null;
  }

  // Calculate item count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Get total for specific vendor
  double totalForVendor(String vendorId) {
    return items
        .where((item) => item.sellerId == vendorId)
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Get items for specific vendor
  List<CartItem> itemsForVendor(String vendorId) {
    return items.where((item) => item.sellerId == vendorId).toList();
  }
}
