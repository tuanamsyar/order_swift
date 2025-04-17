import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new product to the vendor's products subcollection
  Future<void> addProduct(Product product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vendorId = user.uid;
        // Add the product to the vendor's products subcollection
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('products')
            .add({
              'name': product.name,
              'price': product.price,
              'description': product.description,
              'category': product.category,
              'createdAt': Timestamp.now(),
            });
      }
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all products for a vendor
  Future<List<Product>> getProducts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vendorId = user.uid;
        final snapshot =
            await _firestore
                .collection('vendors')
                .doc(vendorId)
                .collection('products')
                .get();

        return snapshot.docs.map((doc) {
          return Product(
            id: doc.id,
            name: doc['name'],
            price: doc['price'],
            description: doc['description'],
            category: doc['category'],
            sellerId: doc['sellerId'],
            vendorId: doc['vendorId'],
            timestamp: doc['createdAt'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Update product details
  Future<void> updateProduct(Product product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vendorId = user.uid;
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('products')
            .doc(product.sellerId)
            .update({
              'name': product.name,
              'price': product.price,
              'description': product.description,
              'category': product.category,
            });
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vendorId = user.uid;
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('products')
            .doc(productId)
            .delete();
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
