import 'package:flutter/material.dart';
import 'package:swift_order/service/firebase_auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  void _login(BuildContext context) async {
    try {
      final user = await _authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/wrapper');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  void _googleSignIn(BuildContext context) async {
    // Default to Buyer (you can add a role selection popup if needed)
    final user = await _authService.signInWithGoogle('Buyer');
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/wrapper');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text("Login"),
            ),
            ElevatedButton(
              onPressed: () => _googleSignIn(context),
              child: Text("Sign in with Google"),
            ),
            TextButton(
              child: Text("Don't have an account? Register"),
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
