
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: EgcColors.okBg, border: Border.all(color: EgcColors.ok, width: 2)),
            child: const Icon(Icons.check_circle_outline, color: EgcColors.ok, size: 44)),
          const SizedBox(height: 24),
          const Text('Commande confirmée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          const Text('Livraison sous 48h — Paiement à réception', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: EgcColors.ink3, height: 1.5)),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(20), width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: EgcColors.line, width: 1.5), borderRadius: EgcRadius.mdBorder),
            child: Column(children: [
              const Text('Numéro de commande', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
              const SizedBox(height: 6),
              Text('#\${orderId.length > 16 ? orderId.substring(0, 16) : orderId}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            ])),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text('Suivre ma commande'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Retour à la boutique', style: TextStyle(color: EgcColors.ink3, fontSize: 14)),
          ),
        ]),
      )),
    );
  }
}
