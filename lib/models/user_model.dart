import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String plan;
  final String planStatus;
  final String? planExpiry;
  final double bonus;
  final double totalEarnings;
  final double cashbacks;
  final int totalOrders;
  final int totalReferrals;
  final String referralCode;
  final String creditCat;
  final int articlesCount;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = '',
    this.plan = 'client',
    this.planStatus = 'pending',
    this.planExpiry,
    this.bonus = 0,
    this.totalEarnings = 0,
    this.cashbacks = 0,
    this.totalOrders = 0,
    this.totalReferrals = 0,
    this.referralCode = '',
    this.creditCat = 'A',
    this.articlesCount = 0,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      city: d['city'] ?? '',
      plan: d['plan'] ?? 'client',
      planStatus: d['planStatus'] ?? 'pending',
      planExpiry: d['planExpiry'],
      bonus: (d['bonus'] ?? 0).toDouble(),
      totalEarnings: (d['totalEarnings'] ?? 0).toDouble(),
      cashbacks: (d['cashbacks'] ?? 0).toDouble(),
      totalOrders: (d['totalOrders'] ?? 0).toInt(),
      totalReferrals: (d['totalReferrals'] ?? 0).toInt(),
      referralCode: d['referralCode'] ?? '',
      creditCat: d['creditCat'] ?? 'A',
      articlesCount: (d['articlesCount'] ?? 0).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'email': email,
    'phone': phone, 'city': city, 'plan': plan,
    'planStatus': planStatus, 'planExpiry': planExpiry,
    'bonus': bonus, 'totalEarnings': totalEarnings,
    'cashbacks': cashbacks, 'totalOrders': totalOrders,
    'totalReferrals': totalReferrals, 'referralCode': referralCode,
    'createdAt': FieldValue.serverTimestamp(),
  };

  bool get isActive => planStatus == 'active';
  bool get isSeller => plan == 'seller';
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : 'C';
}
