
import 'package:flutter/material.dart';

class DropdownMenuField extends StatefulWidget {
  const DropdownMenuField({
    super.key,
    this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.width
  });

  final String? label;
  final String? value;
  final List<DropdownMenuEntry<String>> items;
  final ValueChanged<String?> onChanged;
  final double? width;

  @override
  State<DropdownMenuField> createState() => _DropdownMenuFieldState();
}

class _DropdownMenuFieldState extends State<DropdownMenuField> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenuFormField<String>(
      label: Text(widget.label ?? ''),
      controller: controller,
      onSelected: widget.onChanged,
      dropdownMenuEntries: widget.items,
      textStyle: TextStyle(
        color: Color(0xFF162F48),
      ),
      width: widget.width,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFC6D2DE))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFC6D2DE))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFC6D2DE), width: 1.5)
        )
      ),
    );
  }
}