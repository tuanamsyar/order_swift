import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/pages/login_page.dart';
import 'package:swift_order/seller/order/seller_order_page.dart';
import 'package:swift_order/seller/vendor/vendor_list_page.dart';
import 'package:swift_order/service/firebase_auth_service.dart';
import 'package:swift_order/pages/create_vendor_profile_page.dart';
import 'package:swift_order/seller/product/add_product_page.dart';

class SellerHome extends StatelessWidget {
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  SellerHome({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<bool> _hasVendorProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    // Check if vendor document exists with matching sellerId
    final query =
        await _firestore
            .collection('vendors')
            .where('sellerId', isEqualTo: uid)
            .limit(1)
            .get();

    return query.docs.isNotEmpty;
  }

  void _logout(BuildContext context) async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  void _navigateToCreateProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateVendorProfilePage()),
    );
  }

  void _navigateToOrderList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerOrdersPage()),
    );
  }

  void _navigateToVendorList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Home")),
      body: FutureBuilder<bool>(
        future: _hasVendorProfile(),
        builder: (context, vendorSnapshot) {
          if (vendorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vendorSnapshot.hasError) {
            return Center(child: Text("Error: ${vendorSnapshot.error}"));
          }

          final hasProfile = vendorSnapshot.data ?? false;

          if (!hasProfile) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No vendor profile found."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToCreateProfile(context),
                    child: const Text("Create Vendor Profile"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );
          }

          // Vendor profile exists
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData) {
                return const Center(child: Text("No user data found"));
              }

              final data = userSnapshot.data!;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome, Seller!",
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    Text("Email: ${data['email']}"),
                    Text("Role: ${data['role']}"),
                    const SizedBox(height: 20),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _navigateToVendorList(context),
                      child: const Text("View Vendor List"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _navigateToOrderList(context),
                      child: const Text("View Order List"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _logout(context),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
