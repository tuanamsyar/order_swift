import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Update name and email
  Future<void> updateProfile({
    required String name,
    required String email,
    String? profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('users').doc(user.uid).update({'name': name});

    if (email != user.email) {
      // ignore: deprecated_member_use
      await user.updateEmail(email);
    }

    if (profileImage != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': profileImage,
      });
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Create a unique filename
      String fileName =
          'profile_${currentUser?.uid}${path.extension(imageFile.path)}';

      // Get reference to storage location
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  // Change password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.updatePassword(newPassword);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
