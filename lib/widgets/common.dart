import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

// ── PILL / BADGE DE STATUT ─────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String status;
  final String? label;
  const StatusPill(this.status, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final txt = label ?? (kOrderStatus[status] ?? kArticleStatus[status] ?? kPlanStatus[status] ?? status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusBgColor(status),
        borderRadius: EgcRadius.pill,
      ),
      child: Text(txt, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor(status))),
    );
  }
}

// ── IMAGE ARTICLE ──────────────────────────────────────────────────
class ArticleImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final String category;

  const ArticleImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.category = 'other',
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? EgcRadius.mdBorder;
    if (url == null || url!.isEmpty) {
      return Container(
        width: width, height: height,
        decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: r),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(kCategoryIcons[category] ?? '📦', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(kCategories[category] ?? 'Article', style: const TextStyle(fontSize: 10, color: EgcColors.ink3, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return ClipRRect(
      borderRadius: r,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width, height: height, fit: fit,
        placeholder: (_, __) => Container(color: EgcColors.bg3, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: EgcColors.primary)))),
        errorWidget: (_, __, ___) => Container(
          color: EgcColors.bg3,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(kCategoryIcons[category] ?? '📦', style: const TextStyle(fontSize: 28)),
          ]),
        ),
      ),
    );
  }
}

// ── BOUTON PRIMAIRE ────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;
  const PrimaryButton({super.key, required this.label, this.onTap, this.loading = false, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color ?? EgcColors.primary),
        child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ]),
      ),
    );
  }
}

// ── BOUTON SECONDAIRE ──────────────────────────────────────────────
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const SecondaryButton({super.key, required this.label, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: OutlinedButton(
      onPressed: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 18, color: EgcColors.ink2), const SizedBox(width: 8)],
        Text(label),
      ]),
    ),
  );
}

// ── CHAMP DE SAISIE ────────────────────────────────────────────────
class EgcTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;

  const EgcTextField({
    super.key, required this.label, this.hint,
    this.controller, this.validator,
    this.keyboardType, this.obscure = false,
    this.suffix, this.maxLines = 1, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines,
        enabled: enabled,
        style: const TextStyle(fontSize: 14, color: EgcColors.ink),
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: suffix) : null),
      ),
    ],
  );
}

// ── DROPDOWN ──────────────────────────────────────────────────────
class EgcDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const EgcDropdown({super.key, required this.label, this.value, required this.items, required this.onChanged, this.validator});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink2)),
      const SizedBox(height: 6),
      DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: EgcColors.ink),
        decoration: const InputDecoration(),
        dropdownColor: EgcColors.bg2,
        borderRadius: EgcRadius.mdBorder,
      ),
    ],
  );
}

// ── CARTE KPI ─────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color? color;
  const KpiCard({super.key, required this.emoji, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: EgcColors.bg2,
      borderRadius: EgcRadius.mdBorder,
      border: Border.all(color: EgcColors.line, width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color ?? EgcColors.bg3, borderRadius: BorderRadius.circular(9)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16)))),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: EgcColors.ink3, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── MENU ROW ──────────────────────────────────────────────────────
class MenuRow extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MenuRow({super.key, required this.emoji, required this.bgColor, required this.title, this.subtitle, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EgcColors.ink)),
          if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: const TextStyle(fontSize: 12, color: EgcColors.ink3))],
        ])),
        trailing ?? const Icon(Icons.chevron_right, color: EgcColors.ink3, size: 20),
      ]),
    ),
  );
}

// ── BONUS ROW ─────────────────────────────────────────────────────
class BonusRow extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String date;
  final double amount;

  const BonusRow({super.key, required this.emoji, required this.bgColor, required this.title, required this.date, required this.amount});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(9)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 15)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink)),
        Text(date, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
      ])),
      Text(
        '${amount > 0 ? '+' : ''}${fmtPrice(amount)}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: amount > 0 ? EgcColors.ok : EgcColors.err),
      ),
    ]),
  );
}

// ── SECTION HEADER ────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EgcColors.ink)),
      if (action != null) ...[
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.primary)),
        ),
      ],
    ]),
  );
}

// ── ÉTAT VIDE ─────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({super.key, required this.emoji, required this.title, required this.subtitle, this.buttonLabel, this.onButton});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Opacity(opacity: 0.35, child: Text(emoji, style: const TextStyle(fontSize: 52))),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EgcColors.ink), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: EgcColors.ink3, height: 1.5), textAlign: TextAlign.center),
        if (buttonLabel != null) ...[
          const SizedBox(height: 20),
          SizedBox(width: 180, child: PrimaryButton(label: buttonLabel!, onTap: onButton)),
        ],
      ]),
    ),
  );
}

// ── CHARGEMENT SHIMMER ────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.radius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value, 0),
          colors: [EgcColors.bg3, EgcColors.line2, EgcColors.bg3],
        ),
      ),
    ),
  );
}

// ── NOTICE ────────────────────────────────────────────────────────
class NoticeBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;
  final String emoji;

  const NoticeBox({super.key, required this.text, required this.color, required this.bgColor, required this.emoji});

  factory NoticeBox.orange(String text) => NoticeBox(text: text, color: const Color(0xFF92400E), bgColor: EgcColors.primaryBg, emoji: '⚠️');
  factory NoticeBox.green(String text) => NoticeBox(text: text, color: EgcColors.ok, bgColor: EgcColors.okBg, emoji: '✅');
  factory NoticeBox.blue(String text) => NoticeBox(text: text, color: EgcColors.blue, bgColor: EgcColors.blueBg, emoji: 'ℹ️');

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: bgColor, borderRadius: EgcRadius.smBorder, border: Border.all(color: color.withOpacity(0.3))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji), const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.5, fontWeight: FontWeight.w500))),
    ]),
  );
}
