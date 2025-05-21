import 'package:flutter/material.dart';

class SellerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SellerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
