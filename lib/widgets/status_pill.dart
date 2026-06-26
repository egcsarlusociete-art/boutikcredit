import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class StatusPill extends StatelessWidget {
  final String status;
  final Map<String, String>? labels;

  const StatusPill(this.status, {super.key, this.labels});

  @override
  Widget build(BuildContext context) {
    final label = (labels ?? kOrderStatus)[status] ?? status;
    final color = statusColor(status);
    final bg = statusBgColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: EgcRadius.pill),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
