import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/buyer/order/order_list_page.dart';
import 'package:swift_order/buyer/profile/buyer_edit_profile_page.dart';
import 'package:swift_order/home/buyer_home.dart';
import 'package:swift_order/widgets/buyer_bottom_nav_bar.dart';

class BuyerProfilePage extends StatelessWidget {
  const BuyerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body:
          user == null
              ? const Center(child: Text('No user signed in.'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(user.email ?? 'No email')),
                      ],
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditBuyerProfilePage(),
                          ),
                        );
                      },
                    ),

                    const Spacer(),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

      bottomNavigationBar: BuyerCustomBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => BuyerHome()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => OrderListPage()),
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushNamed(context, '/favorites');
              break;
            case 3:
              // already on profile page
              break;
          }
        },
      ),
    );
  }
}
