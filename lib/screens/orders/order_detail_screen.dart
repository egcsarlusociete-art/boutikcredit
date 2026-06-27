
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_pill.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);
    return ordersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: EgcColors.primary))),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur'))),
      data: (orders) {
        final order = orders.where((o) => o.id == id).firstOrNull;
        if (order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande introuvable')));
        final steps = ['confirmed', 'processing', 'shipped', 'delivered'];
        final si = steps.indexOf(order.status).clamp(0, 3);
        final stepLabels = ['Confirmée', 'Préparation', 'En livraison', 'Livrée'];
        return Scaffold(
          backgroundColor: EgcColors.bg,
          appBar: AppBar(title: Text('#${order.orderId.substring(0, 14)}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            // Status + tracker
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Text('Suivi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const Spacer(), StatusPill(order.status, labels: kOrderStatus)]),
                const SizedBox(height: 16),
                ...List.generate(4, (i) => Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Column(children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: i <= si ? EgcColors.primary : EgcColors.bg3, border: Border.all(color: i <= si ? EgcColors.primary : EgcColors.line2, width: 1.5))),
                      if (i < 3) Container(width: 1.5, height: 28, color: i < si ? EgcColors.primary : EgcColors.line),
                    ]),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stepLabels[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: i <= si ? EgcColors.ink : EgcColors.ink3)),
                      Text(i < si ? 'Terminé' : i == si ? 'En cours' : 'En attente', style: TextStyle(fontSize: 11, color: i <= si ? EgcColors.primary : EgcColors.ink3)),
                    ]),
                  ]))),
              ])),
            const SizedBox(height: 12),
            // Articles
            _section('Articles', Column(children: [
              ...order.items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${i.shop} — Qté ${i.qty}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                  ])),
                  Text(fmtPrice(i.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]))),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(fmtPrice(order.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, color: EgcColors.primary)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Cashback reçu', style: TextStyle(fontSize: 12, color: EgcColors.ok)),
                Text('+${fmtPrice(order.cashbackEarned)}', style: const TextStyle(fontSize: 12, color: EgcColors.ok, fontWeight: FontWeight.w700)),
              ]),
            ])),
            const SizedBox(height: 12),
            _section('Livraison', Text('${order.delivery.name}\n${order.delivery.phone}\n${order.delivery.city} — ${order.delivery.addr}',
              style: const TextStyle(fontSize: 13, color: EgcColors.ink2, height: 1.6))),
            const SizedBox(height: 12),
            _section('Paiement', Text('${order.paymentPlan == "daily" ? "Quotidien" : "Hebdomadaire"}\n${order.paymentMethod.toUpperCase()} — ${order.paymentPhone}',
              style: const TextStyle(fontSize: 13, color: EgcColors.ink2, height: 1.6))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://wa.me/2250152372300?text=Support+commande+%23${order.orderId}')),
              icon: const Icon(Icons.support_agent_outlined, size: 18),
              label: const Text('Contacter le support'),
              style: ElevatedButton.styleFrom(backgroundColor: EgcColors.ok, minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }

  Widget _section(String title, Widget content) => Container(
    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
    child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(color: EgcColors.bg3, borderRadius: BorderRadius.only(topLeft: EgcRadius.md, topRight: EgcRadius.md)),
        child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ink3, letterSpacing: 0.4))),
      Padding(padding: const EdgeInsets.all(14), child: content),
    ]));
}
