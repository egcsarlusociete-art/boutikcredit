import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

class CartService {
  static const _key = 'egc_cart';
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (s, i) => s + i.qty);
  double get subtotal => _items.fold(0, (s, i) => s + i.total);
  double get totalCashback => _items.fold(0, (s, i) => s + i.cashbackTotal);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _items.clear();
      _items.addAll(list.map((m) => CartItem.fromMap(Map<String, dynamic>.from(m))));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((i) => i.toMap()).toList()));
  }

  Future<void> add(ArticleModel article) async {
    final existing = _items.where((i) => i.articleId == article.id);
    if (existing.isNotEmpty) {
      existing.first.qty++;
    } else {
      _items.add(CartItem(
        articleId: article.id,
        name: article.name,
        price: article.price,
        cashback: article.cashback,
        imageUrl: article.imageUrl,
        shopName: article.shopName,
      ));
    }
    await _save();
  }

  Future<void> increment(String articleId) async {
    final item = _items.firstWhere((i) => i.articleId == articleId, orElse: () => throw StateError('Not found'));
    item.qty++;
    await _save();
  }

  Future<void> decrement(String articleId) async {
    final index = _items.indexWhere((i) => i.articleId == articleId);
    if (index < 0) return;
    if (_items[index].qty <= 1) {
      _items.removeAt(index);
    } else {
      _items[index].qty--;
    }
    await _save();
  }

  Future<void> remove(String articleId) async {
    _items.removeWhere((i) => i.articleId == articleId);
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
  }

  double get dailyPayment => (subtotal / 100).ceilToDouble();
  double get weeklyPayment => (subtotal / 15).ceilToDouble();
}
