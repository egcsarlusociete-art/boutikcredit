import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/helpers.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String city,
    required String plan,
    String creditCat = 'A',
    String referralCode = '',
    String shopName = '',
    String location = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password);
    final uid = cred.user!.uid;
    final collection = plan == 'seller' ? 'vendeurs' : 'users';
    final expiry = DateTime.now().add(const Duration(days: 365));
    final data = {
      'uid': uid, 'name': name.trim(), 'email': email.trim(),
      'phone': phone.trim(), 'city': city, 'plan': plan,
      'planStatus': 'pending', 'planExpiry': expiry.toIso8601String(),
      'bonus': 500.0, 'totalEarnings': 500.0, 'cashbacks': 0.0,
      'totalOrders': 0, 'totalReferrals': 0,
      'referralCode': generateReferralCode(),
      'creditCat': creditCat,
      'referredBy': referralCode.isNotEmpty ? referralCode : null,
      'cgvAccepted': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (plan == 'seller') {
      data['shopName'] = shopName.isNotEmpty ? shopName : name;
      data['location'] = location;
      data['articlesCount'] = 0;
    }
    await _db.collection(collection).doc(uid).set(data);
    await _db.collection('bonusHistory').add({
      'userId': uid, 'type': 'welcome', 'amount': 500,
      'label': 'Bonus de bienvenue BoutikCredit',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Créditer le parrain si code parrain fourni
    if (referralCode.isNotEmpty) {
      try {
        // Chercher le parrain dans users et vendeurs
        final usersSnap = await _db.collection('users')
            .where('referralCode', isEqualTo: referralCode).limit(1).get();
        final vendeursSnap = await _db.collection('vendeurs')
            .where('referralCode', isEqualTo: referralCode).limit(1).get();

        DocumentSnapshot? parrain;
        String? parrainCollection;

        if (usersSnap.docs.isNotEmpty) {
          parrain = usersSnap.docs.first;
          parrainCollection = 'users';
        } else if (vendeursSnap.docs.isNotEmpty) {
          parrain = vendeursSnap.docs.first;
          parrainCollection = 'vendeurs';
        }

        if (parrain != null && parrainCollection != null) {
          final parrainId = parrain.id;
          // Créditer 500F au parrain
          await _db.collection(parrainCollection).doc(parrainId).update({
            'bonus': FieldValue.increment(500),
            'totalEarnings': FieldValue.increment(500),
            'totalReferrals': FieldValue.increment(1),
          });
          // Historique bonus parrain
          await _db.collection('bonusHistory').add({
            'userId': parrainId,
            'type': 'referral',
            'amount': 500,
            'label': 'Parrainage de ${name.trim()}',
            'createdAt': FieldValue.serverTimestamp(),
          });
          // Enregistrer le parrainage
          await _db.collection('referrals').add({
            'referrerId': parrainId,
            'referredId': uid,
            'name': name.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // Silencieux si parrain non trouvé
      }
    }
  }

  Future<void> signOut() => _auth.signOut();

  Stream<UserModel?> userStream(String uid) async* {
    yield* _db.collection('users').doc(uid).snapshots().asyncMap((snap) async {
      if (snap.exists) return UserModel.fromFirestore(snap);
      final vSnap = await _db.collection('vendeurs').doc(uid).get();
      if (vSnap.exists) return UserModel.fromFirestore(vSnap);
      return null;
    });
  }

  Future<String> getUserCollection(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? 'users' : 'vendeurs';
  }

  Future<void> resetPassword(String email) =>
    _auth.sendPasswordResetEmail(email: email.trim());
}
