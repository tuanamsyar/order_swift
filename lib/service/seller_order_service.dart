import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/models/order_model.dart';

class SellerOrderService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<OrderModel>> fetchSellerOrders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .orderBy(
              'timestamp',
              descending: true,
            ) // ✅ Sort by timestamp (latest first)
            .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data()))
        .where(
          (order) =>
              order.items.any((item) => item.sellerId == currentUser.uid),
        ) // Only seller's orders
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }
}
