import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryInfo {
  final String name;
  final String phone;
  final String city;
  final String addr;
  const DeliveryInfo({required this.name, required this.phone, required this.city, required this.addr});
  Map<String, dynamic> toMap() => {'name': name, 'phone': phone, 'city': city, 'addr': addr};
  factory DeliveryInfo.fromMap(Map<String, dynamic> m) => DeliveryInfo(
    name: m['name'] ?? '', phone: m['phone'] ?? '', city: m['city'] ?? '', addr: m['addr'] ?? '');
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int qty;
  final double cb;
  final String shop;
  const OrderItem({required this.id, required this.name, required this.price, required this.qty, required this.cb, required this.shop});
  double get total => price * qty;
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price, 'qty': qty, 'cb': cb, 'shop': shop};
  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'] ?? '', name: m['name'] ?? '', price: (m['price'] ?? 0).toDouble(),
    qty: (m['qty'] ?? 1).toInt(), cb: (m['cb'] ?? 3).toDouble(), shop: m['shop'] ?? '');
}

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double cashbackEarned;
  final String paymentPlan;
  final double paymentAmount;
  final String paymentMethod;
  final String paymentPhone;
  final DeliveryInfo delivery;
  final String status;
  final String? estimatedDelivery;
  final DateTime? createdAt;
  final DateTime? processingAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id, required this.orderId, required this.userId,
    required this.items, required this.subtotal, required this.cashbackEarned,
    required this.paymentPlan, required this.paymentAmount,
    required this.paymentMethod, required this.paymentPhone,
    required this.delivery, required this.status,
    this.estimatedDelivery, this.createdAt,
    this.processingAt, this.shippedAt, this.deliveredAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems = d['items'] as List? ?? [];
    return OrderModel(
      id: doc.id, orderId: d['orderId'] ?? doc.id, userId: d['userId'] ?? '',
      items: rawItems.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      cashbackEarned: (d['cashbackEarned'] ?? 0).toDouble(),
      paymentPlan: d['paymentPlan'] ?? 'daily',
      paymentAmount: (d['paymentAmount'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? '',
      paymentPhone: d['paymentPhone'] ?? '',
      delivery: DeliveryInfo.fromMap(Map<String, dynamic>.from(d['delivery'] ?? {})),
      status: d['status'] ?? 'confirmed',
      estimatedDelivery: d['estimatedDelivery'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      processingAt: (d['processingAt'] as Timestamp?)?.toDate(),
      shippedAt: (d['shippedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  List<String> get statusSteps => ['confirmed', 'processing', 'shipped', 'delivered'];
  int get statusIndex => statusSteps.indexOf(status);
  bool get isActive => !['delivered', 'cancelled'].contains(status);
}

class WithdrawalModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String method;
  final String account;
  final String name;
  final String status;
  final DateTime? createdAt;
  final bool? deletedByUser;
  final bool? deletedByAdmin;

  const WithdrawalModel({
    required this.id, required this.userId, required this.userName,
    required this.amount, required this.method, required this.account,
    required this.name, required this.status, this.createdAt,
    this.deletedByUser, this.deletedByAdmin,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id, userId: d['userId'] ?? '', userName: d['userName'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(), method: d['method'] ?? '',
      account: d['account'] ?? '', name: d['name'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      deletedByUser: d['deletedByUser'] as bool?,
      deletedByAdmin: d['deletedByAdmin'] as bool?,
    );
  }
}

class BonusEntry {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String label;
  final DateTime? createdAt;

  const BonusEntry({
    required this.id, required this.userId, required this.type,
    required this.amount, required this.label, this.createdAt,
  });

  factory BonusEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BonusEntry(
      id: doc.id, userId: d['userId'] ?? '', type: d['type'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(), label: d['label'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPositive => amount > 0;
  String get emoji {
    switch (type) {
      case 'cashback': return '🛒';
      case 'referral': return '🔗';
      case 'welcome':  return '🎁';
      case 'withdrawal': return '💸';
      default: return '💎';
    }
  }
}

class ReferralModel {
  final String id;
  final String referrerId;
  final String refereeId;
  final String name;
  final DateTime? createdAt;

  const ReferralModel({
    required this.id, required this.referrerId,
    required this.refereeId, required this.name, this.createdAt,
  });

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      id: doc.id, referrerId: d['referrerId'] ?? '',
      refereeId: d['refereeId'] ?? '', name: d['name'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
