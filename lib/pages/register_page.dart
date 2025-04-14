import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/pages/login_page.dart';
import 'package:swift_order/service/firebase_auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Buyer';
  final _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _register() async {
    try {
      final user = await _authService.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _selectedRole,
      );

      if (user != null) {
        // Create user document in 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'role': _selectedRole,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create wallet document with initial balance of 0
        await _firestore.collection('wallets').doc(user.uid).set({
          'balance': 0.0,
          'currency': 'MYR', // Malaysian Ringgit
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });

        // Navigate to main app screen
        Navigator.pushReplacementNamed(context, '/wrapper');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Select Role",
                  border: OutlineInputBorder(),
                ),
                items:
                    ['Buyer', 'Seller'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("Register", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                child: const Text("Already have an account? Login"),
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
