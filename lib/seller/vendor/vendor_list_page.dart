import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swift_order/seller/vendor/vendor_detail_page.dart';

class VendorListPage extends StatefulWidget {
  const VendorListPage({super.key});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('vendors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final vendor = snapshot.data!.docs[index];
              final data = vendor.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      data['imageUrl'] != null
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(data['imageUrl']),
                          )
                          : const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(
                    data['vendorName'] ?? 'No business name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['vendorDescription'] ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorDetailPage(vendorId: vendor.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
