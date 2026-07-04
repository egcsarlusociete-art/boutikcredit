
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
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
              actions: [
                CircleAvatar(backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18, color: EgcColors.ink),
                    onPressed: () => Share.share('Découvrez ' + a.name + ' sur BoutikCredit !\n💰 ' + fmtPrice(a.price) + '\n📲 https://egc-sarlu.com/app-arm64-v8a-release.apk'),
                  )),
                const SizedBox(width: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('favorites')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                      .where('articleId', isEqualTo: a.id).snapshots(),
                  builder: (ctx, snap) {
                    final isFav = (snap.data?.docs.length ?? 0) > 0;
                    return CircleAvatar(backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 18, color: isFav ? Colors.red : EgcColors.ink),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                          final favSnap = await FirebaseFirestore.instance.collection('favorites')
                              .where('userId', isEqualTo: uid).where('articleId', isEqualTo: a.id).get();
                          if (favSnap.docs.isNotEmpty) {
                            await favSnap.docs.first.reference.delete();
                            if (context.mounted) showSnack(context, 'Retiré des favoris');
                          } else {
                            await FirebaseFirestore.instance.collection('favorites').add({
                              'userId': uid, 'articleId': a.id, 'createdAt': FieldValue.serverTimestamp()
                            });
                            if (context.mounted) showSnack(context, 'Ajouté aux favoris ❤️');
                          }
                        },
                      ));
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _ImageCarousel(article: a))),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _vendeurLogo(a.vendeurId),
                  ),
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
                _feature('✅', 'En stock', 'Qté : ${a.qty}'),
              ]),
              const SizedBox(height: 100),
            ]))),
          ]),
          bottomNavigationBar: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (ctx, snap) {
                final isModifyMode = snap.hasData && snap.data!.getString('modifyOrderId') != null;
                final orderId = snap.data?.getString('modifyOrderId') ?? '';
                final orderRef = snap.data?.getString('modifyOrderRef') ?? '';
                if (isModifyMode) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      // Remplacer l'article dans la commande
                      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                        'modified': true,
                        'modificationRequest': {
                          'newItemId': a.id,
                          'newItemName': a.name,
                          'newItemPrice': a.price,
                          'newItemShop': a.shopName,
                          'requestedAt': FieldValue.serverTimestamp(),
                        }
                      });
                      // Notifier l'admin
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'userId': '9D76f2HLPrNODPN8HtPDbzwG4wA3',
                        'type': 'order', 'read': false,
                        'title': 'Demande de modification commande',
                        'message': 'Commande #$orderRef : remplacement demandé par "${a.name}"',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      // Effacer le mode modification
                      await snap.data!.remove('modifyOrderId');
                      await snap.data!.remove('modifyOrderRef');
                      if (context.mounted) {
                        context.go('/orders');
                        showSnack(context, 'Demande de remplacement envoyée ✅');
                      }
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Remplacer cet article'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: EgcColors.primary),
                  );
                }
                return Row(children: [
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
                ]);
              },
            ),
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
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ink), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(sub, style: const TextStyle(fontSize: 10, color: EgcColors.ink3), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  ));
}

class _ImageCarousel extends StatefulWidget {
  final dynamic article;
  const _ImageCarousel({required this.article});
  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final images = [
      if (widget.article.imageUrl != null) widget.article.imageUrl!,
      if (widget.article.imageUrl2 != null) widget.article.imageUrl2!,
      if (widget.article.imageUrl3 != null) widget.article.imageUrl3!,
    ];

    if (images.isEmpty) {
      return Container(color: EgcColors.bg3, child: const Center(
        child: Icon(Icons.image_outlined, size: 64, color: EgcColors.ink3)));
    }

    if (images.length == 1) {
      return CachedNetworkImage(imageUrl: images[0], fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: EgcColors.bg3));
    }

    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => CachedNetworkImage(
          imageUrl: images[i], fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: EgcColors.bg3)),
      ),
      // Indicateurs de points
      Positioned(bottom: 16, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _current == i ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _current == i ? EgcColors.primary : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ),
      // Compteur images
      Positioned(top: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
          child: Text('${_current + 1}/${images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

Widget _vendeurLogo(String vendeurId) {
  // Map des logos par vendeurId
  const logos = {
    'impactveroty_vendor': 'https://impactveroty.com/logoIMPACT.jpg',
  };
  final url = logos[vendeurId];
  if (url != null) {
    return CachedNetworkImage(
      imageUrl: url,
      width: 40, height: 40,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(color: EgcColors.primaryBg, shape: BoxShape.circle),
        child: const Center(child: Text('🏪', style: TextStyle(fontSize: 20)))),
    );
  }
  return Container(
    width: 40, height: 40,
    decoration: const BoxDecoration(color: EgcColors.primaryBg, shape: BoxShape.circle),
    child: const Center(child: Text('🏪', style: TextStyle(fontSize: 20))));
}
