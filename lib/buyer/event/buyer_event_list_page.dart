import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/buyer/order/order_list_page.dart';
import 'package:swift_order/home/buyer_home.dart';
import 'package:swift_order/widgets/buyer_bottom_nav_bar.dart';
import 'buyer_event_create_page.dart'; // Import your create event page

class BuyerEventListPage extends StatefulWidget {
  const BuyerEventListPage({super.key});

  @override
  State<BuyerEventListPage> createState() => _BuyerEventListPageState();
}

class _BuyerEventListPageState extends State<BuyerEventListPage> {
  final String buyerId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<DocumentSnapshot>> fetchBuyerEvents() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .where('buyerId', isEqualTo: buyerId)
            // .orderBy('date')
            .get();
    return snapshot.docs;
  }

  Future<String> getVendorName(String vendorId) async {
    final vendorDoc =
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .get();
    return vendorDoc.data()?['vendorName'] ?? 'Unknown Vendor';
  }

  Widget buildVendorList(Map<String, dynamic> eventData) {
    final List invitedVendors = eventData['invitedVendors'] ?? [];
    final Map<String, dynamic> responses = Map<String, dynamic>.from(
      eventData['vendorResponses'] ?? {},
    );

    if (invitedVendors.isEmpty) {
      return const Text('No vendors invited.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          invitedVendors.map<Widget>((vendorId) {
            final response = responses[vendorId] ?? 'pending';
            return FutureBuilder<String>(
              future: getVendorName(vendorId),
              builder: (context, snapshot) {
                final vendorName = snapshot.data ?? 'Loading...';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(vendorName),
                      Text(
                        response,
                        style: TextStyle(
                          color:
                              response == 'accepted'
                                  ? Colors.green
                                  : response == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BuyerEventCreatePage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchBuyerEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No events created yet.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerEventCreatePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Event'),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final eventData = events[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventData['eventName'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Date: ${formatDate(eventData['date'])}"),
                      Text("Location: ${eventData['location'] ?? 'N/A'}"),
                      Text("Description: ${eventData['description'] ?? ''}"),
                      const SizedBox(height: 12),
                      const Text(
                        "Vendor Responses:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      buildVendorList(eventData),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BuyerCustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => BuyerHome()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => OrderListPage()),
                (route) => false,
              );
              break;
            case 2:
              // Already on orders page
              break;
            case 3:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => OrderListPage()),
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
