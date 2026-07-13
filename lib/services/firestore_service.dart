import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ARTICLES
  Stream<List<ArticleModel>> publishedArticles() => _db
      .collection('articles')
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) {
        final all = s.docs.map(ArticleModel.fromFirestore).toList();
        // Masquer les articles sans stock
        return all.where((a) => a.stock > 0).toList();
      });

  Stream<List<ArticleModel>> vendeurArticles(String uid) => _db
      .collection('articles')
      .where('vendeurId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ArticleModel.fromFirestore).toList());

  Future<void> submitArticle(Map<String, dynamic> data) =>
      _db.collection('articles').add({
        ...data,
        'status': 'pending',
        'imageUrl': null,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateArticle(String id, Map<String, dynamic> data) =>
      _db.collection('articles').doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  // COMMANDES
  Stream<List<OrderModel>> userOrders(String uid) => _db
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required DeliveryInfo delivery,
    required String paymentPlan,
    required String paymentMethod,
    required String paymentPhone,
  }) async {
    final orderId = 'EGC-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final subtotal = items.fold(0.0, (s, i) => s + i.total);
    final cashback = items.fold(0.0, (s, i) => s + i.cashbackTotal);
    final perPayment = paymentPlan == 'daily'
        ? (subtotal / 100).ceil().toDouble()
        : (subtotal / 15).ceil().toDouble();
    await _db.collection('orders').add({
      'orderId': orderId,
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'cashbackEarned': cashback,
      'paymentPlan': paymentPlan,
      'paymentAmount': perPayment,
      'paymentMethod': paymentMethod,
      'paymentPhone': paymentPhone,
      'delivery': delivery.toMap(),
      'status': 'confirmed',
      'estimatedDelivery': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final coll = await _getUserColl(userId);
    await _db.collection(coll).doc(userId).update({
      'bonus': FieldValue.increment(cashback),
      'totalEarnings': FieldValue.increment(cashback),
      'cashbacks': FieldValue.increment(cashback),
      'totalOrders': FieldValue.increment(1),
    });
    await _db.collection('bonusHistory').add({
      'userId': userId, 'type': 'cashback', 'amount': cashback,
      'label': 'Cashback commande ${orderId.substring(0, 12)}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Deduire le stock de chaque article commande
    for (final item in items) {
      await _db.collection('articles').doc(item.articleId).update({
        'stock': FieldValue.increment(-item.qty),
      });
    }
    // Notifier chaque vendeur
    final vendeurIds = items.map((i) => i.vendeurId).toSet();
    for (final vendeurId in vendeurIds) {
      final vendeurItems = items.where((i) => i.vendeurId == vendeurId).toList();
      final itemNames = vendeurItems.map((i) => i.name).take(2).join(', ');
      await _db.collection('notifications').add({
        'userId': vendeurId,
        'type': 'order',
        'title': '\u0001F6CD\uFE0F Nouvelle commande !',
        'message': vendeurItems.length.toString() + ' article(s) : ' + itemNames,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return orderId;
  }

  // BONUS
  Stream<List<BonusEntry>> bonusHistory(String uid) => _db
      .collection('bonusHistory')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(BonusEntry.fromFirestore).toList());

  // RETRAITS
  Stream<List<WithdrawalModel>> userWithdrawals(String uid) => _db
      .collection('withdrawals')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
        .map(WithdrawalModel.fromFirestore)
        .where((w) => w.deletedByUser != true)
        .toList());

  Future<void> requestWithdrawal({
    required String userId, required String userName,
    required double amount, required String method,
    required String account, required String holderName,
  }) async {
    await _db.collection('withdrawals').add({
      'userId': userId, 'userName': userName, 'amount': amount,
      'method': method, 'account': account, 'name': holderName,
      'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // PARRAINAGE
  Stream<List<ReferralModel>> userReferrals(String uid) => _db
      .collection('referrals')
      .where('referrerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ReferralModel.fromFirestore).toList());

  Future<void> registerReferral({
    required String referrerId, required String refereeId, required String refereeName,
  }) async {
    await _db.collection('referrals').add({
      'referrerId': referrerId, 'refereeId': refereeId,
      'name': refereeName, 'createdAt': FieldValue.serverTimestamp(),
    });
    final coll = await _getUserColl(referrerId);
    await _db.collection(coll).doc(referrerId).update({
      'bonus': FieldValue.increment(1000),
      'totalEarnings': FieldValue.increment(1000),
      'totalReferrals': FieldValue.increment(1),
    });
    await _db.collection('bonusHistory').add({
      'userId': referrerId, 'type': 'referral', 'amount': 1000,
      'label': 'Parrainage de $refereeName',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ADMIN
  Stream<List<ArticleModel>> allArticles() => _db
      .collection('articles')
      .snapshots().map((s) => s.docs.map(ArticleModel.fromFirestore).toList());

  Stream<List<UserModel>> allUsers() => _db
      .collection('users')
      .snapshots().map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Stream<List<UserModel>> allVendeurs() => _db
      .collection('vendeurs')
      .snapshots().map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Stream<List<OrderModel>> allOrders() {
    return _db
      .collection('orders')
      .where('status', whereIn: ['confirmed', 'processing', 'shipped', 'delivered', 'cancelled'])
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());
  }

  Stream<List<WithdrawalModel>> allWithdrawals() => _db
      .collection('withdrawals')
      .snapshots()
      .map((s) => s.docs
        .map(WithdrawalModel.fromFirestore)
        .where((w) => w.deletedByAdmin != true)
        .toList());

  Future<void> adminUpdateArticle(String id, Map<String, dynamic> data) =>
      _db.collection('articles').doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> adminUpdateOrderStatus(String id, String status) {
    final dateField = {
      'processing': 'processingAt',
      'shipped': 'shippedAt',
      'delivered': 'deliveredAt',
      'cancelled': 'cancelledAt',
    }[status];
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (dateField != null) updates[dateField] = FieldValue.serverTimestamp();
    return _db.collection('orders').doc(id).update(updates);
  }

  Future<void> adminApproveWithdrawal(String id, String userId, double amount) async {
    // Approuver le retrait
    await _db.collection('withdrawals').doc(id).update({'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()});
    
    // Calculer le nombre de filleuls à supprimer (1 filleul = 500 F)
    final nbFilleuls = (amount / 500).floor();
    if (nbFilleuls <= 0) return;
    
    // Récupérer les filleuls actifs du plus ancien au plus récent
    final allRefs = await _db.collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .orderBy('createdAt', descending: false).get();
    
    final activeRefs = <dynamic>[];
    for (final ref in allRefs.docs) {
      final referredId = (ref.data()['referredId'] ?? '') as String;
      if (referredId.isEmpty) continue;
      final uSnap = await _db.collection('users').doc(referredId).get();
      final vSnap = await _db.collection('vendeurs').doc(referredId).get();
      final status = uSnap.exists ? (uSnap.data()?['planStatus'] ?? '') : (vSnap.data()?['planStatus'] ?? '');
      if (status == 'active') activeRefs.add(ref);
      if (activeRefs.length >= nbFilleuls) break;
    }
    
    if (activeRefs.length < nbFilleuls) {
      throw Exception('Pas assez de filleuls actifs (\${activeRefs.length}/\$nbFilleuls requis)');
    }
    
    // Supprimer les filleuls et leur bonusHistory
    for (final ref in activeRefs) {
      await _db.collection('referrals').doc(ref.id).delete();
      final bonusSnap = await _db.collection('bonusHistory')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'referral').get();
      if (bonusSnap.docs.isNotEmpty) await bonusSnap.docs.first.reference.delete();
    }
    
    // Mettre à jour totalReferrals
    final coll = await _getUserColl(userId);
    await _db.collection(coll).doc(userId).update({
      'totalReferrals': FieldValue.increment(-nbFilleuls),
    });
  }

  Future<void> adminRejectWithdrawal(String id, String userId, double amount) async {
    await _db.collection('withdrawals').doc(id).update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
  }

  Future<void> adminActivateUser(String id, String coll) async {
    final expiry = DateTime.now().add(const Duration(days: 365)).toIso8601String();
    await _db.collection(coll).doc(id).update({
      'planStatus': 'active', 'planExpiry': expiry,
      'activatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _getUserColl(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? 'users' : 'vendeurs';
  }
}
