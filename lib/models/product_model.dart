import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final String? sellerId;
  final String vendorId;
  final DateTime timestamp;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.sellerId,
    required this.vendorId,
    required this.timestamp,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['productName'] ?? '',
      description: data['productDescription'] ?? '',
      price: (data['productPrice'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['productCategory'] ?? 'Uncategorized',
      sellerId: data['sellerId'] ?? '',
      vendorId: data['vendorId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
