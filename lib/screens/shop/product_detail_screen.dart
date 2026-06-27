
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../services/providers.dart';
import 'shop_screen.dart';

import '../../utils/theme.dart';
import '../../utils/helpers.dart';


class ProductDetailScreen extends ConsumerWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artAsync = ref.watch(publishedArticlesProvider);
    return artAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: EgcColors.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur'))),
      data: (list) {
        final a = list.where((x) => x.id == id).firstOrNull;
        if (a == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Article introuvable')));
        return Scaffold(
          backgroundColor: EgcColors.bg2,
          body: CustomScrollView(slivers: [
            SliverAppBar(expandedHeight: 300, pinned: true, backgroundColor: EgcColors.bg2,
              leading: Padding(padding: const EdgeInsets.all(8),
                child: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: EgcColors.ink), onPressed: () => context.pop()))),
              flexibleSpace: FlexibleSpaceBar(
                background: a.hasImage
                  ? CachedNetworkImage(imageUrl: a.imageUrl!, fit: BoxFit.cover)
                  : Container(color: EgcColors.bg3, child: const Center(child: Text('📦', style: TextStyle(fontSize: 80)))))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.pill),
                  child: Text(kCategories[a.category] ?? a.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.primary))),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
                  child: Text('+${fmtPrice(a.cashbackAmount)} cashback', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ok))),
              ]),
              const SizedBox(height: 12),
              Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtPrice(a.price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(bottom: 2),
                  child: Text(fmtPrice(a.oldPrice), style: const TextStyle(fontSize: 14, color: EgcColors.ink3, decoration: TextDecoration.lineThrough))),
              ]),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: EgcRadius.mdBorder),
                child: Text(a.description.isEmpty ? 'Aucune description.' : a.description, style: const TextStyle(fontSize: 14, color: EgcColors.ink2, height: 1.6))),
              const SizedBox(height: 16),
              // Vendeur
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: EgcColors.line, width: 1.5), borderRadius: EgcRadius.mdBorder),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: EgcColors.primaryBg, shape: BoxShape.circle),
                    child: const Center(child: Text('🏪', style: TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.shopName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                    Text('${a.vendeurCity} — Membre EGC-SARLU', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                  ])),
                ])),
              const SizedBox(height: 20),
              Row(children: [
                _feature('🚚', 'Livraison', 'Gratuite sous 48h'),
                const SizedBox(width: 10),
                _feature('📅', 'Paiement', 'Étalé · Dès réception'),
                const SizedBox(width: 10),
                _feature('✅', 'En stock', 'Qté : \${a.qty}'),
              ]),
              const SizedBox(height: 100),
            ]))),
          ]),
          bottomNavigationBar: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { ref.read(cartProvider.notifier).add(a); context.pop(); showSnack(context, 'Ajouté au panier ✓'); },
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                label: const Text('Panier'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () { ref.read(cartProvider.notifier).add(a); context.go('/cart'); },
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Acheter'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              )),
            ]),
          )),
        );
      },
    );
  }

  Widget _feature(String icon, String title, String sub) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(border: Border.all(color: EgcColors.line, width: 1.5), borderRadius: EgcRadius.mdBorder),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ink), textAlign: TextAlign.center),
      Text(sub, style: const TextStyle(fontSize: 10, color: EgcColors.ink3), textAlign: TextAlign.center),
    ]),
  ));
}
