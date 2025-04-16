import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductPage extends StatefulWidget {
  final String vendorId;
  final String productId;

  const EditProductPage({
    super.key,
    required this.vendorId,
    required this.productId,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isLoading = false;

  final List<String> _categories = ['Food', 'Drink', 'Snack', 'Dessert'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final DocumentReference _productRef;

  @override
  void initState() {
    super.initState();
    _productRef = _firestore
        .collection('vendors')
        .doc(widget.vendorId)
        .collection('products')
        .doc(widget.productId);
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _productRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['productName'] ?? '';
        _priceController.text = data['productPrice']?.toString() ?? '';
        _descController.text = data['productDescription'] ?? '';
        if (data['productCategory'] != null &&
            _categories.contains(data['productCategory'])) {
          _selectedCategory = data['productCategory'];
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading product: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _productRef.update({
        'productName': _nameController.text.trim(),
        'productPrice': double.parse(_priceController.text.trim()),
        'productDescription': _descController.text.trim(),
        'productCategory': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProduct,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a price';
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter a description'
                                    : null,
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
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProduct,
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Update Product'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
