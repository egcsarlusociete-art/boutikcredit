import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/article_model.dart';
import '../models/order_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStream;
});

// Données utilisateur
final userDataProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return AuthService().userStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(userDataProvider.stream);
});

// Articles publics — accessible sans connexion
final publishedArticlesProvider = StreamProvider<List<ArticleModel>>((ref) {
  return FirestoreService().publishedArticles();
});

// Commandes utilisateur
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().userOrders(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Retraits utilisateur
final withdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().userWithdrawals(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Historique bonus
final bonusHistoryProvider = StreamProvider<List<BonusEntry>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().bonusHistory(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Parrainages
final referralsProvider = StreamProvider<List<ReferralModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().userReferrals(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Articles vendeur
final vendorArticlesProvider = StreamProvider<List<ArticleModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().vendeurArticles(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Admin
final allArticlesProvider = StreamProvider<List<ArticleModel>>((ref) {
  return ref.watch(firestoreServiceProvider).allArticles();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).allUsers();
});

final allVendeursProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).allVendeurs();
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firestoreServiceProvider).allOrders();
});

final allWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  return ref.watch(firestoreServiceProvider).allWithdrawals();
});
