import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  final String? vendorId; // Make this optional

  const AddProductPage({super.key, this.vendorId});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Food';
  String? _vendorId;
  bool _isLoading = false;

  final List<String> _categories = ['Food', 'Drink', 'Snack', 'Dessert'];

  @override
  void initState() {
    super.initState();
    // If vendorId was passed in, use it, otherwise fetch it
    if (widget.vendorId != null) {
      _vendorId = widget.vendorId;
    } else {
      _fetchVendorId();
    }
  }

  Future<void> _fetchVendorId() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(
                'vendors',
              ) // Fix typo if this is wrong (should be 'vendors' or 'vendors'?)
              .where('sellerId', isEqualTo: uid)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _vendorId = querySnapshot.docs.first.id;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No vendor profile found! Please create one first.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching vendor: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addProduct() async {
    if (_vendorId == null) return;

    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descController.text.trim();

    if (name.isEmpty || priceText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final price = double.parse(priceText);
      setState(() => _isLoading = true);

      final docRef =
          FirebaseFirestore.instance
              .collection('vendors')
              .doc(_vendorId)
              .collection('products')
              .doc();

      await docRef.set({
        'productId': docRef.id,
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'vendorId': _vendorId,
        'productName': name,
        'productPrice': price,
        'productDescription': description,
        'productCategory': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items:
                          _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategory = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _vendorId == null ? null : _addProduct,
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              ),
    );
  }
}
