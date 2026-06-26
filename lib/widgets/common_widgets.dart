
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

// ── LOGO EGC ──────────────────────────────────────────────────────
class EgcLogo extends StatelessWidget {
  final double size;
  const EgcLogo({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.smBorder),
    alignment: Alignment.center,
    child: Text('E', style: TextStyle(color: Colors.white, fontSize: size * 0.5, fontWeight: FontWeight.w800)),
  );
}

// ── PILL STATUT ───────────────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String status;
  final Map<String, String> labels;
  const StatusPill(this.status, {super.key, this.labels = const {}});
  @override
  Widget build(BuildContext context) {
    final label = labels[status] ?? kOrderStatus[status] ?? kArticleStatus[status] ?? kPlanStatus[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: statusBgColor(status), borderRadius: EgcRadius.pill),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor(status))),
    );
  }
}

// ── BOUTON PRIMAIRE ───────────────────────────────────────────────
class EgcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final double height;
  const EgcButton({super.key, required this.label, this.onTap, this.loading = false, this.icon, this.color, this.height = 50});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height, width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color ?? EgcColors.primary, disabledBackgroundColor: EgcColors.primary.withOpacity(.5)),
      child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
    ),
  );
}

// ── BOUTON SECONDAIRE ─────────────────────────────────────────────
class EgcOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const EgcOutlineButton({super.key, required this.label, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50, width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label),
      ]),
    ),
  );
}

// ── CHAMP DE FORMULAIRE ───────────────────────────────────────────
class EgcTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final TextInputAction action;
  final void Function(String)? onChanged;
  const EgcTextField({
    super.key, required this.label, this.hint, this.controller,
    this.validator, this.keyboardType = TextInputType.text,
    this.obscure = false, this.suffix, this.maxLines = 1,
    this.action = TextInputAction.next, this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink2)),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller, validator: validator,
        keyboardType: keyboardType, obscureText: obscure,
        maxLines: maxLines, textInputAction: action,
        onChanged: onChanged,
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
      ),
    ],
  );
}

// ── SELECT DROPDOWN ───────────────────────────────────────────────
class EgcDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<Map<String, String>> items;
  final void Function(String?) onChanged;
  const EgcDropdown({super.key, required this.label, this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink2)),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(),
        items: items.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!))).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

// ── IMAGE PRODUIT ─────────────────────────────────────────────────
class ArticleImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const ArticleImage({super.key, this.url, this.width = double.infinity, this.height = 200, this.borderRadius});
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: width, height: height,
        decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: borderRadius),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📦', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text('Aucune image', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
        ]),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url!, width: width, height: height, fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: EgcColors.bg3, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (c, u, e) => Container(color: EgcColors.bg3, child: const Center(child: Text('📦', style: TextStyle(fontSize: 40)))),
      ),
    );
  }
}

// ── CARTE AVEC TITRE ──────────────────────────────────────────────
class EgcCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const EgcCard({super.key, this.title, required this.child, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: EgcRadius.mdBorder,
    child: Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder,
        border: Border.all(color: EgcColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    ),
  );
}

// ── MENU ROW ──────────────────────────────────────────────────────
class MenuRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String emoji;
  final Color bgColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  const MenuRow({super.key, required this.title, this.subtitle, required this.emoji, required this.bgColor, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: EgcColors.line))),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: bgColor, borderRadius: EgcRadius.smBorder),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EgcColors.ink)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
          ],
        )),
        trailing ?? const Icon(Icons.chevron_right, color: EgcColors.ink3, size: 20),
      ]),
    ),
  );
}

// ── LOADING SHIMMER ───────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? radius;
  const ShimmerBox({super.key, this.width = double.infinity, required this.height, this.radius});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: radius ?? EgcRadius.smBorder),
  );
}

// ── ÉTAT VIDE ─────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EgcColors.ink), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: EgcColors.ink3), textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: 24), action!],
      ]),
    ),
  );
}

// ── SECTION HEADER ────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EgcColors.ink)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.primary)),
          ),
      ],
    ),
  );
}

// ── BONUS ROW ────────────────────────────────────────────────────
class BonusRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String date;
  final double amount;
  const BonusRow({super.key, required this.emoji, required this.label, required this.date, required this.amount});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: amount > 0 ? EgcColors.okBg : EgcColors.errBg,
          borderRadius: EgcRadius.smBorder,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(date, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
        ],
      )),
      Text(
        '${amount > 0 ? '+' : ''}${fmtPrice(amount)}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: amount > 0 ? EgcColors.ok : EgcColors.err),
      ),
    ]),
  );
}
