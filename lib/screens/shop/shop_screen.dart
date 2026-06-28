import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/providers.dart';
import '../../models/article_model.dart';
import '../../utils/theme.dart';
import '../../models/credit_category.dart' as cc;
import '../../utils/helpers.dart';
import '../../widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Provider articles publiés


// Provider panier (local)
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('egc_cart');
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((m) => CartItem.fromMap(Map<String,dynamic>.from(m))).toList();
      state = list;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('egc_cart', jsonEncode(state.map((i) => i.toMap()).toList()));
  }

  void add(ArticleModel a) {
    final idx = state.indexWhere((i) => i.articleId == a.id);
    if (idx >= 0) {
      final s = List.of(state); s[idx].qty++; state = s;
    } else {
      state = [...state, CartItem(articleId: a.id, name: a.name, price: a.price, cashback: a.cashback, imageUrl: a.imageUrl, shopName: a.shopName)];
    }
    _save();
  }

  void remove(String id) { state = state.where((i) => i.articleId != id).toList(); _save(); }
  void increment(String id) { final i = state.indexWhere((x) => x.articleId == id); if (i >= 0) { final s2 = List.of(state); s2[i].qty++; state = s2; _save(); } }
  void decrement(String id) { final i = state.indexWhere((x) => x.articleId == id); if (i >= 0) { if (state[i].qty <= 1) remove(id); else { final s3 = List.of(state); s3[i].qty--; state = s3; _save(); } } }
  void clear() { state = []; _save(); }

  int get totalQty => state.fold(0, (s, i) => s + i.qty);
  double get total => state.fold(0.0, (s, i) => s + i.total);
  double get totalCashback => state.fold(0.0, (s, i) => s + i.cashbackTotal);
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _cat = 'all';
  String _search = '';
  final _searchC = TextEditingController();

  List<ArticleModel> _filter(List<ArticleModel> list) {
    var r = list;
    if (_cat != 'all') r = r.where((a) => a.category == _cat).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      r = r.where((a) => a.name.toLowerCase().contains(q) || a.shopName.toLowerCase().contains(q)).toList();
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(publishedArticlesProvider);
    final cart = ref.watch(cartProvider);
    final cartCount = cart.fold(0, (s, i) => s + i.qty);

    return Scaffold(
      backgroundColor: EgcColors.bg,
      body: CustomScrollView(slivers: [
        // AppBar
        SliverAppBar(
          pinned: true, floating: true,
          backgroundColor: EgcColors.bg2,
          title: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: EgcColors.primary, borderRadius: BorderRadius.circular(7)),
              child: const Center(child: Text('E', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 8),
            RichText(text: const TextSpan(
              text: 'EGC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.ink),
              children: [TextSpan(text: '.SARLU', style: TextStyle(color: EgcColors.primary))])),
          ]),
          actions: [
            Stack(children: [
              IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.go('/cart')),
              if (cartCount > 0) Positioned(top: 6, right: 6,
                child: Container(width: 16, height: 16,
                  decoration: const BoxDecoration(color: EgcColors.primary, shape: BoxShape.circle),
                  child: Center(child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
            ]),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchC,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un article, un vendeur...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: EgcColors.ink3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: EgcColors.bg3,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
        ),

        // Hero
        SliverToBoxAdapter(child: _hero(articlesAsync)),
        // Plafond credit
        SliverToBoxAdapter(child: _PlafondWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Catégories
        SliverToBoxAdapter(
          child: SizedBox(height: 42, child: ListView(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            children: kCategories.entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _cat = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _cat == e.key ? EgcColors.primary : EgcColors.bg2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cat == e.key ? EgcColors.primary : EgcColors.line, width: 1.5),
                  ),
                  child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cat == e.key ? Colors.white : EgcColors.ink2)),
                ),
              ),
            )).toList(),
          )),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Grille produits
        articlesAsync.when(
          loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: EgcColors.primary)))),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('📦', style: TextStyle(fontSize: 48)), const SizedBox(height: 12), const Text('Chargement en cours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)), const SizedBox(height: 8), const Text('Vérifiez votre connexion internet', style: TextStyle(fontSize: 13, color: EgcColors.ink3))])))),
          data: (articles) {
            final filtered = _filter(articles);
            if (filtered.isEmpty) return SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Aucun article trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                Text('Essayez d\'autres filtres', style: const TextStyle(fontSize: 13, color: EgcColors.ink3)),
              ]),
            ));
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.62),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ProductCard(article: filtered[i], onAddToCart: () {
                    ref.read(cartProvider.notifier).add(filtered[i]);
                    showSnack(context, '${filtered[i].name} ajouté au panier ✓');
                  }),
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _hero(AsyncValue<List<ArticleModel>> async) {
    final count = async.valueOrNull?.length ?? 0;
    final vendors = async.valueOrNull?.map((a) => a.vendeurId).toSet().length ?? 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: EgcColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Marketplace EGC-SARLU', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        const Text('Des milliers d\'articles,\nlivrés en 48h.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        const Text('Cashback garanti · Paiement étalé · Sans apport', style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [
          _stat('$count', 'Articles'),
          const SizedBox(width: 24),
          _stat('$vendors', 'Vendeurs'),
          const SizedBox(width: 24),
          _stat('48h', 'Livraison'),
        ]),
      ]),
    );
  }

  Widget _stat(String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);
}

class _PlafondWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final cartAsync = ref.watch(cartProvider);
    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final cat = cc.kCategories.firstWhere((c) => c.id == user.creditCat, orElse: () => cc.kCategories.first);
        final cartTotal = cartAsync.fold(0.0, (s, i) => s + i.total);
        final spent = user.totalOrders > 0 ? cartTotal : cartTotal;
        final restant = (cat.plafond - spent).clamp(0.0, cat.plafond);
        final pct = ((cat.plafond - restant) / cat.plafond).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EgcColors.bg2,
            borderRadius: EgcRadius.mdBorder,
            border: Border.all(color: EgcColors.line, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('💳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Plafond Catégorie ${cat.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              const Spacer(),
              Text(fmtPrice(restant), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: EgcRadius.pill,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: EgcColors.bg3,
                valueColor: AlwaysStoppedAnimation<Color>(pct > 0.8 ? EgcColors.err : EgcColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Panier : ${fmtPrice(cartTotal)}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
              Text('Plafond max : ${fmtPrice(cat.plafond)}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
            ]),
            if (restant == 0) ...[
              const SizedBox(height: 6),
              const Text('⚠️ Plafond atteint — vous ne pouvez plus ajouter d\'articles', style: TextStyle(fontSize: 11, color: EgcColors.err, fontWeight: FontWeight.w600)),
            ] else if (pct > 0.8) ...[
              const SizedBox(height: 6),
              Text('⚠️ Il vous reste ${fmtPrice(restant)} de disponible', style: const TextStyle(fontSize: 11, color: EgcColors.gold, fontWeight: FontWeight.w600)),
            ],
          ]),
        );
      },
    );
  }
}
