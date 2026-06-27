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

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(authServiceProvider).userStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});


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
final publishedArticlesProvider = StreamProvider<List<ArticleModel>>((ref) {
  return ref.watch(firestoreServiceProvider).publishedArticles();
});

final vendorArticlesProvider = StreamProvider<List<ArticleModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(firestoreServiceProvider).vendeurArticles(uid);
});

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(firestoreServiceProvider).userOrders(uid);
});

final userWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(firestoreServiceProvider).userWithdrawals(uid);
});

final bonusHistoryProvider = StreamProvider<List<BonusEntry>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(firestoreServiceProvider).bonusHistory(uid);
});

final userReferralsProvider = StreamProvider<List<ReferralModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(firestoreServiceProvider).userReferrals(uid);
});

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

