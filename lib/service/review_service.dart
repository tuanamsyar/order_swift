import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new review
  Future<void> addReview({
    required String vendorId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous';

    await _firestore.collection('reviews').add({
      'userId': user.uid,
      'userName': userName,
      'vendorId': vendorId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update vendor's average rating
    await _updateVendorRating(vendorId);
  }

  // Get reviews for a vendor
  Stream<List<Review>> getVendorReviews(String vendorId) {
    return _firestore
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList(),
        );
  }

  // Update vendor's average rating
  Future<void> _updateVendorRating(String vendorId) async {
    final reviews =
        await _firestore
            .collection('reviews')
            .where('vendorId', isEqualTo: vendorId)
            .get();

    if (reviews.docs.isEmpty) return;

    final totalRating = reviews.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );
    final averageRating = totalRating / reviews.docs.length;

    await _firestore.collection('vendors').doc(vendorId).update({
      'rating': averageRating,
      'reviewCount': reviews.docs.length,
    });
  }
}
