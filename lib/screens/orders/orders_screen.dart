
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_pill.dart';

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return FirestoreService().userOrders(uid);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e, _) => Center(child: Text('Erreur de chargement')),
        data: (orders) {
          if (orders.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Aucune commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 8),
            const Text('Vos commandes apparaîtront ici', style: TextStyle(color: EgcColors.ink3)),
            const SizedBox(height: 24),
            SizedBox(width: 180, child: ElevatedButton(onPressed: () => context.go('/'), child: const Text('Découvrir la boutique'))),
          ]));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _orderCard(ctx, orders[i]),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final steps = ['confirmed', 'processing', 'shipped', 'delivered'];
    final si = steps.indexOf(order.status).clamp(0, 3);
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#${order.orderId.length > 14 ? order.orderId.substring(0, 14) : order.orderId}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const Spacer(),
            StatusPill(order.status, labels: kOrderStatus),
          ]),
          const SizedBox(height: 4),
          Text(fmtDate(order.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
          const SizedBox(height: 12),
          // Progress
          Row(children: List.generate(4, (i) => Expanded(child: Row(children: [
            Expanded(child: Container(height: 3, color: i <= si ? EgcColors.primary : EgcColors.bg3)),
            if (i < 3) const SizedBox(width: 2),
          ])))),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${order.items.length} article(s)', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
            Text(fmtPrice(order.subtotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.ink)),
          ]),
        ])),
    );
  }
}
