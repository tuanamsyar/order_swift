import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:swift_order/buyer/cart/cart_page.dart';
import 'package:swift_order/buyer/order/order_confirmation_page.dart';
import 'package:swift_order/pages/create_vendor_profile_page.dart';
import 'package:swift_order/pages/login_page.dart';
import 'package:swift_order/pages/register_page.dart';
import 'package:swift_order/pages/wrapper.dart';
import 'package:swift_order/service/cart_service.dart';
import 'package:swift_order/service/firebase_auth_service.dart';
import 'package:swift_order/service/wallet_service.dart';
import 'package:swift_order/widgets/app_constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WalletService.initStripe(publishableKey);
  // Stripe.publishableKey = publishableKey;
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        Provider<CartService>(create: (_) => CartService()),
        // Add other providers here as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swift Ordering Management',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Wrapper(),
      routes: {
        '/login': (_) => LoginPage(),
        '/register': (_) => RegisterPage(),
        '/wrapper': (_) => Wrapper(),
        '/createVendorProfile': (_) => const CreateVendorProfilePage(),
        '/cart': (_) => CartPage(),
        // Add this line for cart navigation
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
