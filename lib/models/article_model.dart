import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleModel {
  final String id;
  final String vendeurId;
  final String vendeurName;
  final String shopName;
  final String vendeurCity;
  final String name;
  final String category;
  final String description;
  final String state;
  final double price;
  final int qty;
  final String? imageUrl;
  final String? imageUrl2;
  final String? imageUrl3;
  final String status;
  final int views;
  final double cashback;
  final String? rdvDate;
  final String? rdvSlot;
  final String? address;
  final String? ref;
  final DateTime? createdAt;

  const ArticleModel({
    required this.id,
    required this.vendeurId,
    required this.vendeurName,
    required this.shopName,
    this.vendeurCity = '',
    required this.name,
    required this.category,
    this.description = '',
    this.state = 'new',
    required this.price,
    this.qty = 1,
    this.imageUrl,
    this.imageUrl2,
    this.imageUrl3,
    this.status = 'pending',
    this.views = 0,
    this.cashback = 3,
    this.rdvDate,
    this.rdvSlot,
    this.address,
    this.ref,
    this.createdAt,
  });

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ArticleModel(
      id: doc.id,
      vendeurId: d['vendeurId'] ?? '',
      vendeurName: d['vendeurName'] ?? '',
      shopName: d['shopName'] ?? '',
      vendeurCity: d['vendeurCity'] ?? '',
      name: d['name'] ?? '',
      category: d['category'] ?? 'other',
      description: d['description'] ?? '',
      state: d['state'] ?? 'new',
      price: (d['price'] ?? 0).toDouble(),
      qty: (d['qty'] ?? 1).toInt(),
      imageUrl: d['imageUrl'],
      imageUrl2: d['imageUrl2'],
      imageUrl3: d['imageUrl3'],
      status: d['status'] ?? 'pending',
      views: (d['views'] ?? 0).toInt(),
      cashback: (d['cashback'] ?? 3).toDouble(),
      rdvDate: d['rdvDate'],
      rdvSlot: d['rdvSlot'],
      address: d['address'],
      ref: d['ref'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  double get oldPrice => price * 1.2;
  double get discount => ((oldPrice - price) / oldPrice * 100).roundToDouble();
  double get cashbackAmount => (price * cashback / 100).roundToDouble();
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

class CartItem {
  final String articleId;
  final String name;
  final double price;
  final double cashback;
  final String? imageUrl;
  final String shopName;
  int qty;

  CartItem({
    required this.articleId,
    required this.name,
    required this.price,
    required this.cashback,
    this.imageUrl,
    required this.shopName,
    this.qty = 1,
  });

  double get total => price * qty;
  double get cashbackTotal => (total * cashback / 100).roundToDouble();

  Map<String, dynamic> toMap() => {
    'id': articleId, 'name': name, 'price': price,
    'cb': cashback, 'img': imageUrl, 'shop': shopName, 'qty': qty,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    articleId: m['id'] ?? '',
    name: m['name'] ?? '',
    price: (m['price'] ?? 0).toDouble(),
    cashback: (m['cb'] ?? 3).toDouble(),
    imageUrl: m['img'],
    shopName: m['shop'] ?? '',
    qty: (m['qty'] ?? 1).toInt(),
  );
}
