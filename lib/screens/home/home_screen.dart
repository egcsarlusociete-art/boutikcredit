import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../video/video_screen.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  int _tabIndex(String location) {
    if (location.startsWith('/cart'))    return 2;
    if (location.startsWith('/orders'))  return 1;
    if (location.startsWith('/bonus'))   return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _openVideos() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Videos',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const Align(
        alignment: Alignment.centerRight,
        child: SizedBox(width: double.infinity, child: VideoScreen()),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabIndex(location);
    return Scaffold(
      body: widget.child,
      floatingActionButton: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: _openVideos,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: EgcColors.err,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: EgcColors.err.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
              Positioned(top: 6, right: 6, child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Center(child: Text('▶', style: TextStyle(fontSize: 6, color: EgcColors.err))),
              )),
            ]),
          ),
        ),
      ),
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
