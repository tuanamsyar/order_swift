// models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String vendorId;
  final double rating;
  final String comment;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vendorId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      vendorId: data['vendorId'],
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'vendorId': vendorId,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
