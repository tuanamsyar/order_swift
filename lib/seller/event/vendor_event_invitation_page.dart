import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorEventInvitationPage extends StatefulWidget {
  const VendorEventInvitationPage({Key? key}) : super(key: key);

  @override
  State<VendorEventInvitationPage> createState() =>
      _VendorEventInvitationPageState();
}

class _VendorEventInvitationPageState extends State<VendorEventInvitationPage> {
  String? vendorId;

  @override
  void initState() {
    super.initState();
    _loadVendorId();
  }

  Future<void> _loadVendorId() async {
    final sellerId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('vendors')
            .where('sellerId', isEqualTo: sellerId)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        vendorId = snapshot.docs.first.id; // the vendor doc ID
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vendor profile not found')));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInvitations() async {
    if (vendorId == null) return [];

    final eventSnapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .where('invitedVendors', arrayContains: vendorId)
            .get();

    List<Map<String, dynamic>> invitations = [];

    for (var doc in eventSnapshot.docs) {
      final data = doc.data();
      final buyerId = data['buyerId'];

      // Fetch buyer name from 'users' collection
      final buyerSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(buyerId)
              .get();

      final buyerName = buyerSnapshot.data()?['name'] ?? 'Unknown Buyer';

      invitations.add({
        'eventId': doc.id,
        'eventName': data['eventName'],
        'description': data['description'],
        'location': data['location'],
        'date': (data['date'] as Timestamp).toDate(),
        'buyerId': buyerId,
        'buyerName': buyerName,
        'vendorResponse':
            (data['vendorResponses'] ?? {})[vendorId] ?? 'pending',
      });
    }

    return invitations;
  }

  Future<void> _updateResponse(String eventId, String response) async {
    if (vendorId == null) return;

    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'vendorResponses.$vendorId': response,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Response updated to "$response"')));

    setState(() {}); // refresh the screen
  }

  @override
  Widget build(BuildContext context) {
    if (vendorId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Event Invitations')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchInvitations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final invitations = snapshot.data ?? [];

          if (invitations.isEmpty) {
            return const Center(child: Text('No invitations found.'));
          }

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation['eventName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Name: ${invitation['buyerName']}'),
                      Text('Location: ${invitation['location']}'),
                      Text('Date: ${invitation['date']}'),
                      const SizedBox(height: 4),
                      Text(invitation['description']),
                      const SizedBox(height: 12),
                      Text(
                        'Your response: ${invitation['vendorResponse']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      if (invitation['vendorResponse'] == 'pending')
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  () => _updateResponse(
                                    invitation['eventId'],
                                    'accepted',
                                  ),
                              icon: const Icon(Icons.check),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _updateResponse(
                                    invitation['eventId'],
                                    'rejected',
                                  ),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
