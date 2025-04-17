// buyer/vendor_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swift_order/buyer/product/buyerProduct_list_page.dart'; // You'll need to create this

class BuyerVendorDetailPage extends StatelessWidget {
  final String vendorId;

  const BuyerVendorDetailPage({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final vendorRef = FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorId);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: vendorRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Vendor not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              if (data['imageUrl'] != null)
                Image.network(
                  data['imageUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['vendorName'] ?? 'Vendor',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['vendorDescription'] ?? 'No description available',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BuyerProductListPage(vendorId: vendorId),
                          ),
                        );
                      },
                      child: const Text('View Products'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
