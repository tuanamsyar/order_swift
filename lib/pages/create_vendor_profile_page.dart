import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/home/seller_home.dart';
import 'package:swift_order/service/vendor_service.dart';

class CreateVendorProfilePage extends StatefulWidget {
  const CreateVendorProfilePage({super.key});

  @override
  _CreateVendorProfilePageState createState() =>
      _CreateVendorProfilePageState();
}

class _CreateVendorProfilePageState extends State<CreateVendorProfilePage> {
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final VendorService _vendorService = VendorService();
  bool _isLoading = false;

  Future<void> _createVendorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _vendorService.createVendorProfile(
        vendorName: _storeNameController.text.trim(),
        vendorDescription: _storeDescriptionController.text.trim(),
        sellerId: user.uid,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SellerHome()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating profile: $e")));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vendor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(labelText: 'Store Name'),
            ),
            TextField(
              controller: _storeDescriptionController,
              decoration: const InputDecoration(labelText: 'Store Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createVendorProfile,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
