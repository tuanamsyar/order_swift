// lib/service/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createEvent({
    required String buyerId,
    required String eventName,
    required String location,
    required String description,
    required DateTime date,
    required List<String> invitedVendorIds,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('events').doc();

    final eventData = {
      'eventId': docRef.id,
      'buyerId': FirebaseAuth.instance.currentUser!.uid,
      'eventName': eventName,
      'location': location,
      'description': description,
      'date': Timestamp.fromDate(date),
      'timestamp': Timestamp.now(),
      'invitedVendors': invitedVendorIds,
      'vendorResponses': {
        for (var vendorId in invitedVendorIds) vendorId: 'pending',
      },
    };

    await docRef.set(eventData);
  }

  Future<List<Map<String, dynamic>>> fetchBuyerEvents() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    final query =
        await _firestore
            .collection('events')
            .where('buyerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return query.docs.map((doc) => doc.data()).toList();
  }
}
