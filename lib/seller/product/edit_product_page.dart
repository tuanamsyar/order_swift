import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  bool _isImageChanged = false;
  File? _newImageFile;
  String? _currentImageUrl;
  String? _newImageUrl;

  final List<String> _categories = ['Food', 'Drink', 'Snack', 'Dessert'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
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
        _currentImageUrl = data['productImage'];

        if (data['productCategory'] != null &&
            _categories.contains(data['productCategory'])) {
          _selectedCategory = data['productCategory'];
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading product: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newImageFile = File(pickedFile.path);
          _isImageChanged = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<String?> _uploadImage() async {
    if (_newImageFile == null) return null;

    try {
      // Delete old image if exists
      if (_currentImageUrl != null) {
        await _deleteImage(_currentImageUrl!);
      }

      final String fileName =
          'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_newImageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Upload new image if changed
      if (_isImageChanged) {
        _newImageUrl = await _uploadImage();
      }

      final updateData = {
        'productName': _nameController.text.trim(),
        'productPrice': double.parse(_priceController.text.trim()),
        'productDescription': _descController.text.trim(),
        'productCategory': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update image if it's changed
      if (_isImageChanged) {
        updateData['productImage'] = _newImageUrl!;
      }

      await _productRef.update(updateData);

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

  Widget _buildImageWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400] ?? Colors.grey),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_newImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_newImageFile!, fit: BoxFit.cover),
              )
            else if (_currentImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Product Image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: const Icon(Icons.edit, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildImageWidget(),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a price';
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter a description'
                                    : null,
                      ),
                      const SizedBox(height: 16),
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProduct,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Update Product'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
