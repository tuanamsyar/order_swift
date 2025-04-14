import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String role,
    String selectedRole,
  ) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;
    await _saveUserToFirestore(user, role);
    return user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signInWithGoogle(String role) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);
    final user = result.user;

    // Check if user already exists in Firestore
    final doc = await _firestore.collection("users").doc(user!.uid).get();
    if (!doc.exists) {
      await _saveUserToFirestore(user, role); // Save role if new user
    }

    return user;
  }

  Future<void> _saveUserToFirestore(User? user, String role) async {
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).set({
        'email': user.email,
        'role': role,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
