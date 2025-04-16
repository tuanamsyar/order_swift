import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/models/order_model.dart';

class SellerOrderService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<OrderModel>> fetchSellerOrders() async {
    final sellerId = _auth.currentUser!.uid;

    final snapshot = await _firestore.collection('orders').get();
    final allOrders =
        snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();

    // Filter orders that include items belonging to the seller
    final sellerOrders =
        allOrders.where((order) {
          return order.items.any((item) => item.sellerId == sellerId);
        }).toList();

    return sellerOrders;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }
}
