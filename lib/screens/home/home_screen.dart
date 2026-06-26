import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  int _tabIndex(String location) {
    if (location.startsWith('/cart'))    return 2;
    if (location.startsWith('/orders'))  return 1;
    if (location.startsWith('/bonus'))   return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: EgcColors.line, width: 1))),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/');        break;
              case 1: context.go('/orders');  break;
              case 2: context.go('/cart');    break;
              case 3: context.go('/bonus');   break;
              case 4: context.go('/profile'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined),       activeIcon: Icon(Icons.storefront),         label: 'Boutique'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined),      activeIcon: Icon(Icons.inventory_2),        label: 'Commandes'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined),    activeIcon: Icon(Icons.shopping_cart),      label: 'Panier'),
            BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_outlined),activeIcon: Icon(Icons.workspace_premium),  label: 'Bonus'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),            activeIcon: Icon(Icons.person),             label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
