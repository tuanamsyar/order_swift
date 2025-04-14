import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  final String sellerId; // Add this field

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.sellerId,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: doc.id,
      name: data['name'],
      price: data['price'],
      imageUrl: data['imageUrl'],
      quantity: data['quantity'],
      sellerId: data['sellerId'], // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'sellerId': sellerId, // Add this
    };
  }
}
