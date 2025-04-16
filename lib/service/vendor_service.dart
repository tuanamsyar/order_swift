import 'package:cloud_firestore/cloud_firestore.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createVendorProfile({
    required String vendorName,
    required String vendorDescription,
    required String sellerId,
  }) async {
    try {
      // Create vendor document with auto-generated ID
      final vendorDocRef = _firestore.collection('vendors').doc();

      await vendorDocRef.set({
        'vendorId': vendorDocRef.id,
        'vendorName': vendorName,
        'vendorDescription': vendorDescription,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user document with vendor reference
      await _firestore.collection('users').doc(sellerId).update({
        'vendorId': vendorDocRef.id,
      });

      return vendorDocRef.id;
    } catch (e) {
      throw Exception('Failed to create vendor profile: $e');
    }
  }

  Future<bool> sellerHasVendorProfile(String sellerId) async {
    try {
      final query =
          await _firestore
              .collection('vendors')
              .where('sellerId', isEqualTo: sellerId)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check vendor profile: $e');
    }
  }
}
