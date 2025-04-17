import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swift_order/home/buyer_home.dart';
import 'package:swift_order/home/seller_home.dart';
import 'package:swift_order/pages/create_vendor_profile_page.dart';
import '../pages/login_page.dart';

class Wrapper extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<bool> _checkVendorProfile(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('vendors')
              .where('sellerId', isEqualTo: userId)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print('Error checking vendor profile: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) return LoginPage();

        final userData = snapshot.data!;
        final role = userData['role'];
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (role == 'Seller') {
          return FutureBuilder<bool>(
            future: _checkVendorProfile(userId!),
            builder: (context, vendorSnapshot) {
              if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!vendorSnapshot.hasData || !vendorSnapshot.data!) {
                return CreateVendorProfilePage();
              }

              return SellerHome();
            },
          );
        }

        if (role == 'Buyer') return BuyerHome();

        return LoginPage();
      },
    );
  }
}
