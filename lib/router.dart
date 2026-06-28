import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/shop/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/cart/order_success_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/bonus/bonus_screen.dart';
import 'screens/referral/referral_screen.dart';
import 'screens/withdrawal/withdrawal_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/vendor/vendor_home_screen.dart';
import 'screens/vendor/vendor_add_article_screen.dart';
import 'screens/vendor/vendor_articles_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/cgv/cgv_screen.dart';

const String kAdminUid = '9D76f2HLPrNODPN8HtPDbzwG4wA3';

// Listenable qui ecoute les changements Firebase Auth
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final _authNotifier = _AuthChangeNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final isLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/',        builder: (c, s) => const ShopScreen()),
          GoRoute(path: '/cart',    builder: (c, s) => const CartScreen()),
          GoRoute(path: '/orders',  builder: (c, s) => const OrdersScreen()),
          GoRoute(path: '/bonus',   builder: (c, s) => const BonusScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/product/:id',   builder: (c, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/checkout',      builder: (c, s) => const CheckoutScreen()),
      GoRoute(path: '/order-success', builder: (c, s) => OrderSuccessScreen(orderId: s.uri.queryParameters['id'] ?? '')),
      GoRoute(path: '/order/:id',     builder: (c, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/referral',      builder: (c, s) => const ReferralScreen()),
      GoRoute(path: '/withdrawal',    builder: (c, s) => const WithdrawalScreen()),
      GoRoute(path: '/vendor',            builder: (c, s) => const VendorHomeScreen()),
      GoRoute(path: '/vendor/articles',   builder: (c, s) => const VendorArticlesScreen()),
      GoRoute(path: '/vendor/add-article',builder: (c, s) => const VendorAddArticleScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminScreen()),
      GoRoute(path: '/cgv', builder: (c, s) => const CgvScreen()),
    ],
  );
});
