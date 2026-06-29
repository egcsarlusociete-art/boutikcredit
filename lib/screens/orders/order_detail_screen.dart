
import 'package:flutter/material.dart';
import '../../services/providers.dart';
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
        final stepLabels = ['Confirmée', 'En préparation', 'En livraison', 'Livrée'];
        final isDelivered = order.status == 'delivered';
        final isCancelled = order.status == 'cancelled';
        return Scaffold(
          backgroundColor: EgcColors.bg,
          appBar: AppBar(title: Text('#${order.orderId.length > 14 ? order.orderId.substring(0, 14) : order.orderId}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            // Ecran livraison
            if (isDelivered) Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.okLine, width: 2)),
              child: Column(children: const [
                Text('🎉', style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text('Article livré avec succès !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.ok)),
                SizedBox(height: 4),
                Text('Votre commande a été livrée et réceptionnée.', style: TextStyle(fontSize: 13, color: EgcColors.ok), textAlign: TextAlign.center),
              ]),
            ),
            if (isCancelled) Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Color(0xFFFEE2E2), borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.err, width: 2)),
              child: const Column(children: [
                Text('❌', style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text('Commande annulée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.err)),
              ]),
            ),
            // Status + tracker
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Text('Suivi de commande', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const Spacer(), StatusPill(order.status, labels: kOrderStatus)]),
                const SizedBox(height: 16),
                ...List.generate(4, (i) => Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Column(children: [
                      Container(width: 28, height: 28,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: i <= si ? EgcColors.primary : EgcColors.bg3,
                          border: Border.all(color: i <= si ? EgcColors.primary : EgcColors.line2, width: 1.5)),
                        child: Center(child: Text(i <= si ? '✓' : '${i+1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                            color: i <= si ? Colors.white : EgcColors.ink3)))),
                      if (i < 3) Container(width: 2, height: 32, color: i < si ? EgcColors.primary : EgcColors.line),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(stepLabels[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: i <= si ? EgcColors.ink : EgcColors.ink3)),
                        if (i < si) ...[
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
                            child: const Text('Validé ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EgcColors.ok))),
                        ],
                      ]),
                      Builder(builder: (_) {
                        final dates = [order.createdAt, order.processingAt, order.shippedAt, order.deliveredAt];
                        final dateStr = dates[i] != null ? fmtDate(dates[i]) : null;
                        final label = i < si ? 'Étape validée' : i == si ? (order.status == 'delivered' ? 'Réceptionnée ✓' : 'En cours...') : 'En attente';
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(label, style: TextStyle(fontSize: 11, color: i <= si ? EgcColors.primary : EgcColors.ink3)),
                          if (dateStr != null) Text(dateStr, style: const TextStyle(fontSize: 10, color: EgcColors.ink3)),
                        ]);
                      }),
                    ])),
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
            const SizedBox(height: 12),
            _section('📅 Suivi des paiements', Builder(builder: (_) {
              final isDaily = order.paymentPlan == 'daily';
              final total = order.subtotal * 1.15; // avec 15% intérêts
              final paiement = isDaily ? total / 100 : total / 15;
              final duree = isDaily ? 100 : 15;
              final unite = isDaily ? 'jours' : 'semaines';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Montant total avec intérêts', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
                  Text(fmtPrice(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.ink)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Paiement ${isDaily ? "quotidien" : "hebdomadaire"}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                  Text(fmtPrice(paiement), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.primary)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Durée totale', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
                  Text('$duree $unite', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                ]),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Bouton paiement CinetPay
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.primaryMid)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Text('💳', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Payer via CinetPay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.primaryDark)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Effectuez votre paiement ${isDaily ? "quotidien" : "hebdomadaire"} de ${fmtPrice(paiement)} via Mobile Money.', style: const TextStyle(fontSize: 12, color: EgcColors.ink2, height: 1.5)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://checkout.cinetpay.com/?apikey=VOTRE_CLE_CINETPAY&site_id=VOTRE_SITE_ID&transaction_id=${order.orderId}&amount=${paiement.round()}&currency=XOF&description=Paiement+commande+${order.orderId}&notify_url=https://egcsarlu-app-b2ba4.web.app/api/notify')),
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text('Payer ${fmtPrice(paiement)}'),
                      style: ElevatedButton.styleFrom(backgroundColor: EgcColors.primary, minimumSize: const Size(double.infinity, 46)),
                    ),
                    const SizedBox(height: 6),
                    const Text('✅ Orange Money · MTN MoMo · Moov · Wave', style: TextStyle(fontSize: 11, color: EgcColors.ink3, height: 1.5)),
                  ]),
                ),
              ]);
            })),
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
