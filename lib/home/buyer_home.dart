import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/buyer/product/buyerProduct_list_page.dart';
import 'package:swift_order/pages/login_page.dart';
import 'package:swift_order/pages/wallet_page.dart';
import 'package:swift_order/service/firebase_auth_service.dart';
import 'package:swift_order/buyer/vendor/buyerVendor_detail_page.dart';
import 'package:swift_order/widgets/custom_bottom_nav_bar.dart'; // Import the custom navbar

class BuyerHome extends StatefulWidget {
  @override
  _BuyerHomeState createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0; // Track the selected index for bottom nav

  Future<Map<String, dynamic>?> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  void _logout(BuildContext context) async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  // Handle bottom navigation bar taps
  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // You could also implement navigation to different pages based on index
    // For example:
    /*
    if (index != 0) { // If not home
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _getPageForIndex(index),
        ),
      ).then((_) {
        setState(() => _currentIndex = 0); // Reset to home when returning
      });
    }
    */
  }

  // Optional: Helper method to get the appropriate page based on index
  /*
  Widget _getPageForIndex(int index) {
    switch (index) {
      case 1:
        return OrdersPage();
      case 2:
        return FavoritesPage();
      case 3:
        return ProfilePage();
      default:
        return Container(); // Should never happen
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                title: Row(
                  children: [
                    Text(
                      "Swift Order",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor.withOpacity(0.8),
                        theme.primaryColor,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _logout(context),
                ),
              ],
            ),

            // User Profile Section
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Error loading user data"),
                    );
                  }
                  final data = snapshot.data!;
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.primaryColor.withOpacity(0.2),
                          child: Text(
                            (data['name'] ?? 'B')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back,",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${data['name'] ?? 'Buyer'}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                data['email'] ?? '',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: theme.primaryColor),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Add this in your SliverToBoxAdapter section after the user profile
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WalletPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Wallet Balance",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<DocumentSnapshot>(
                                stream:
                                    _firestore
                                        .collection('wallets')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                        )
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text(
                                      "Error loading balance",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return const Text(
                                      "Loading...",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                  final data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                  final balance =
                                      data?['balance']?.toStringAsFixed(2) ??
                                      '0.00';
                                  return Text(
                                    "RM$balance",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Categories",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "See All",
                            style: TextStyle(color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryItem(
                            context,
                            "Restaurants",
                            Icons.restaurant,
                            Colors.orange,
                          ),
                          _buildCategoryItem(
                            context,
                            "Grocery",
                            Icons.shopping_basket,
                            Colors.green,
                          ),
                          _buildCategoryItem(
                            context,
                            "Electronics",
                            Icons.devices,
                            Colors.blue,
                          ),
                          _buildCategoryItem(
                            context,
                            "Fashion",
                            Icons.shopping_bag,
                            Colors.purple,
                          ),
                          _buildCategoryItem(
                            context,
                            "Services",
                            Icons.miscellaneous_services,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vendors Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular Vendors",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "See All",
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vendors List
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('vendors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No vendors available')),
                  );
                }

                final vendors = snapshot.data!.docs;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final vendor = vendors[index];
                      final data = vendor.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      BuyerProductListPage(vendorId: vendor.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vendor image at the top (could be a placeholder or real image)
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child:
                                      data['imageUrl'] != null
                                          ? Image.network(
                                            data['imageUrl'],
                                            fit: BoxFit.cover,
                                          )
                                          : Center(
                                            child: Icon(
                                              Icons.store,
                                              size: 50,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                ),
                              ),
                              // Vendor details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['vendorName'] ?? 'Vendor',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Rating display
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                data['rating']?.toString() ??
                                                    '4.5',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['vendorDescription'] ??
                                          'No description',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    // Tags/Categories
                                    if (data['categories'] != null)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            (data['categories'] as List).map<
                                              Widget
                                            >((cat) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  cat,
                                                  style: TextStyle(
                                                    color: theme.primaryColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            data['location'] ?? 'Location',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: vendors.length),
                  ),
                );
              },
            ),
            // Add some bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      // Use the custom bottom navigation bar component
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
