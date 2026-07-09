import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../video/video_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  int _newVideosCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNewVideos();
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

  Future<void> _loadNewVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getInt('lastSeenVideos') ?? 0;
    final videos = await ref.read(bcVideosProvider.future);
    final newCount = videos.where((v) {
      final pub = v.publishedAt;
      if (pub == null) return false;
      return pub.millisecondsSinceEpoch > lastSeen;
    }).length;
    if (mounted) setState(() => _newVideosCount = newCount);
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
              boxShadow: [BoxShadow(color: EgcColors.err.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
              if (_newVideosCount > 0) Positioned(top: 4, right: 4, child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text('$_newVideosCount', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: EgcColors.err)),
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
