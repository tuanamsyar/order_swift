import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? productImage;
  final String category;
  final String? sellerId;
  final String vendorId;
  final String? vendorName; // Default value
  final DateTime timestamp;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.productImage,
    required this.category,
    required this.sellerId,
    required this.vendorId,
    this.vendorName,
    required this.timestamp,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['productName'] ?? '',
      description: data['productDescription'] ?? '',
      price: (data['productPrice'] ?? 0).toDouble(),
      productImage: data['productImage'],
      category: data['productCategory'] ?? 'Uncategorized',
      sellerId: data['sellerId'] ?? '',
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
