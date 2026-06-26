import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class EgcTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const EgcTextField({
    super.key, required this.label, this.hint, this.controller,
    this.validator, this.keyboardType = TextInputType.text,
    this.obscure = false, this.maxLines = 1, this.suffix,
    this.inputFormatters, this.onChanged, this.textInputAction, this.focusNode,
  });

  @override
  State<EgcTextField> createState() => _EgcTextFieldState();
}

class _EgcTextFieldState extends State<EgcTextField> {
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscure && !_showPass,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      style: const TextStyle(fontSize: 15, color: EgcColors.ink, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: widget.obscure
          ? IconButton(
              icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: EgcColors.ink3, size: 20),
              onPressed: () => setState(() => _showPass = !_showPass),
            )
          : widget.suffix,
      ),
    );
  }
}

class EgcDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const EgcDropdown({
    super.key, required this.label, this.value,
    required this.items, required this.onChanged, this.validator,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    validator: validator,
    style: const TextStyle(fontSize: 15, color: EgcColors.ink, fontWeight: FontWeight.w500),
    decoration: InputDecoration(labelText: label),
    dropdownColor: EgcColors.bg2,
    borderRadius: EgcRadius.mdBorder,
  );
}
