import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  final String sellerId;
  final String vendorId;
  final String vendorName; // Default value

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.sellerId,
    required this.vendorId,
    required this.vendorName,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: doc.id,
      name: data['name'],
      price: data['price'],
      imageUrl: data['imageUrl'],
      quantity: data['quantity'],
      sellerId: data['sellerId'],
      vendorId: data['vendorId'],
      vendorName: data['vendorName'], // Add this
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      name: map['name'],
      price: map['price'].toDouble(),
      imageUrl: map['imageUrl'],
      quantity: map['quantity'],
      sellerId: map['sellerId'],
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'sellerId': sellerId,
      'vendorId': vendorId,
      'vendorName': vendorName,
    };
  }
}
