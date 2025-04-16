import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/models/product_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get cart items stream
  Stream<QuerySnapshot> getCartItems() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Get real-time item count stream
  Stream<int> get itemCountStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<int>(0, (sum, doc) {
            final data = doc.data();
            return sum + ((data['quantity'] as num?)?.toInt() ?? 1);
          }),
        );
  }

  // Get total item count (one-time)
  Future<int> get itemCount async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .get();

    return snapshot.docs.fold<int>(0, (sum, doc) {
      final data = doc.data();
      return sum + ((data['quantity'] as num?)?.toInt() ?? 1);
    });
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(product.id);

    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({
        'quantity': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await cartRef.set({
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'vendorId': product.vendorId,
        'sellerId': product.sellerId,
        'quantity': quantity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFromCart(String productId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  Future<void> updateCartItemQuantity(String productId, int newQuantity) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    if (newQuantity <= 0) {
      return removeFromCart(productId);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> clearCart() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final batch = _firestore.batch();
    final cartItems =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .get();

    for (final doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get cart total value
  Future<double> get cartTotal async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0.0;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .get();

    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      final data = doc.data();
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
      return sum + (price * quantity);
    });
  }
}
