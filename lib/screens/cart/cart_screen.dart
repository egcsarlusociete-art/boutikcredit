
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_button.dart';
import '../../services/providers.dart';
import '../../screens/shop/shop_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final total = cart.fold(0.0, (s, i) => s + i.total);
    final cashback = cart.fold(0.0, (s, i) => s + i.cashbackTotal);

    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: Text('Mon panier (\${cart.length})')),
      body: cart.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🛒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Votre panier est vide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 8),
            const Text('Parcourez le catalogue et ajoutez des articles', style: TextStyle(color: EgcColors.ink3)),
            const SizedBox(height: 24),
            SizedBox(width: 180, child: EgcButton(label: 'Voir le catalogue', onTap: () => context.go('/'), icon: Icons.storefront_outlined)),
          ]))
        : Column(children: [
            Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
              ...cart.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
                child: Row(children: [
                  ClipRRect(borderRadius: EgcRadius.smBorder,
                    child: SizedBox(width: 72, height: 72,
                      child: item.imageUrl != null
                        ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: EgcColors.bg3, child: const Center(child: Text('📦', style: TextStyle(fontSize: 28)))))
                        : Container(color: EgcColors.bg3, child: const Center(child: Text('📦', style: TextStyle(fontSize: 28)))))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                    const SizedBox(height: 2),
                    Text(item.shopName, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                    const SizedBox(height: 4),
                    Text(fmtPrice(item.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: EgcColors.ink)),
                    Text('+\${fmtPrice(item.cashbackTotal)} cashback', style: const TextStyle(fontSize: 11, color: EgcColors.ok, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _qtyBtn(Icons.remove, () => notifier.decrement(item.articleId)),
                      Container(width: 36, alignment: Alignment.center,
                        child: Text('\${item.qty}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                      _qtyBtn(Icons.add, () => notifier.increment(item.articleId)),
                      const Spacer(),
                      TextButton(onPressed: () => notifier.remove(item.articleId),
                        child: const Text('Retirer', style: TextStyle(fontSize: 12, color: EgcColors.err))),
                    ]),
                  ])),
                ]),
              )),
            ])),
            Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: const BoxDecoration(color: EgcColors.bg2, border: Border(top: BorderSide(color: EgcColors.line))),
              child: SafeArea(child: Column(children: [
                _sumRow('Sous-total', fmtPrice(total)),
                _sumRow('Livraison', 'Gratuite', valueColor: EgcColors.ok),
                _sumRow('Cashback estimé', '+\${fmtPrice(cashback)}', valueColor: EgcColors.ok),
                const Divider(),
                _sumRow('Total', fmtPrice(total), bold: true),
                const SizedBox(height: 12),
                EgcButton(label: 'Passer la commande', onTap: () => context.push('/checkout'), icon: Icons.lock_outline),
                const SizedBox(height: 8),
              ]))),
          ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border.all(color: EgcColors.line2), borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, size: 16, color: EgcColors.ink2)));

  Widget _sumRow(String label, String value, {bool bold = false, Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, color: bold ? EgcColors.ink : EgcColors.ink3, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
      Text(value, style: TextStyle(fontSize: bold ? 16 : 14, color: valueColor ?? EgcColors.ink, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
    ]));
}
