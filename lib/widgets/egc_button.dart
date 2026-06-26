import 'package:flutter/material.dart';
import '../utils/theme.dart';

class EgcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final Color? color;
  final IconData? icon;
  final double height;

  const EgcButton({
    super.key, required this.label, this.onTap,
    this.loading = false, this.outlined = false,
    this.color, this.icon, this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? EgcColors.primary;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
        ? OutlinedButton(
            onPressed: loading ? null : onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: bg, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: EgcRadius.mdBorder),
            ),
            child: _child(bg),
          )
        : ElevatedButton(
            onPressed: loading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: EgcRadius.mdBorder),
            ),
            child: _child(Colors.white),
          ),
    );
  }

  Widget _child(Color textColor) => loading
    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
    : Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18, color: textColor), const SizedBox(width: 8)],
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15)),
      ]);
}
